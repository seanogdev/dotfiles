#!/usr/bin/env bash
# Test and improve skill description triggering accuracy.
#
# Method: https://agentskills.io/skill-creation/optimizing-descriptions
#   - Score a set of labeled queries against the skill's current description.
#   - Split queries into train (60%) and validation (40%) sets.
#   - Revise the description from train-set failures only.
#   - Repeat, then keep whichever iteration scored best on validation.
#
# This does not use the official skill-creator optimizer. It is a small,
# from-scratch loop over this repo's own skills.
#
# Usage:
#   _scripts/optimize-skill-descriptions.sh                    # every skill in skills/
#   _scripts/optimize-skill-descriptions.sh <skill-name>       # one skill
#   _scripts/optimize-skill-descriptions.sh --eval-only <skill-name>  # score, do not revise
#
# Requires: claude, jq, python3, bc.
#
# COST AND SAFETY NOTE: each query is a real, billed `claude -p` call.
#
# Safety: do not trust --restricted, --disallowedTools, or
# --permission-prompts none for this. --restricted and --disallowedTools
# remove Bash from the tool list the model sees, which changes its own
# routing decision (it gives up before ever considering the skill,
# instead of reaching for it) -- that is a different test, not a safer
# one. --permission-prompts none was tested live in this repo and did NOT
# block Bash: it ran real commands (read-only, as it happened) against
# the real $HOME and the real dotfiles repo. The only mechanism that
# actually worked: stream the run and kill the subprocess the instant it
# announces a tool call that could have a real side effect (Bash, Edit,
# Write, NotebookEdit, WebFetch, Task) -- before Claude Code executes it,
# not after. Read-only tools (Read, Grep, Glob, ToolSearch, WebSearch)
# are let through so a skill that only triggers after some legitimate
# exploration is not miscounted as a miss. This is still a race (the kill
# signal and the tool's own execution both take real time), not a
# guarantee -- treat every run as capable of doing something real if a
# query happens to provoke a very fast Bash/Edit/Write call.
#
# Cost: RUNS x query-count calls per set, x up to MAX_ITERATIONS x 2 sets
# (train, validation) per skill. Start small: RUNS=1 on one skill, look
# at the cost, then scale up. MAX_TOTAL_COST_USD is a hard stop, but it
# only counts calls that finished naturally -- a call killed early for
# using a risky tool is not reflected in the running total.

set -euo pipefail
cd "$(dirname "$0")/.."

EVAL_DIR="evals/descriptions"
RUNS_DIR="evals/.runs"
RUNS="${RUNS:-3}"
MAX_ITERATIONS="${MAX_ITERATIONS:-5}"
THRESHOLD="${THRESHOLD:-0.5}"
MAX_COST_PER_QUERY_USD="${MAX_COST_PER_QUERY_USD:-0.50}"
MAX_TOTAL_COST_USD="${MAX_TOTAL_COST_USD:-5.00}"
TOTAL_COST_USD=0
SAFE_EVAL_TOOLS=" Read Grep Glob ToolSearch WebSearch "
EVAL_ONLY=0

log() { printf '  [%s] %s\n' "$1" "$2"; }

if [[ "${1:-}" == "--eval-only" ]]; then
  EVAL_ONLY=1
  shift
fi

skill_field() {
  # skill_field <SKILL.md> <field>
  awk -v field="$2:" '
    /^---$/ { n++; next }
    n==1 && index($0, field)==1 { sub("^" field " *", ""); print; exit }
  ' "$1"
}

get_description() { skill_field "$1" "description"; }

set_description() {
  local skill_md="$1" new_desc="$2"
  python3 - "$skill_md" "$new_desc" <<'PY'
import re, sys
path, new_desc = sys.argv[1], sys.argv[2]
new_desc = " ".join(new_desc.split())
text = open(path).read()
head, sep, rest = text.partition("---\n")
front, sep2, body = rest.partition("\n---\n")
front = re.sub(r"(?m)^description:.*$", "description: " + new_desc, front, count=1)
open(path, "w").write(head + sep + front + sep2 + body)
PY
}

# Runs one query in a disposable cwd, streaming the response. Read-only
# tools (SAFE_EVAL_TOOLS) are let through so exploration before a Skill
# call is not miscounted as a miss. The instant any other tool is
# announced (Bash, Edit, Write, NotebookEdit, WebFetch, Task, or Skill
# itself), the subprocess is killed -- before that tool actually runs.
# Adds this query's cost (only for calls that finished naturally; a
# killed call reports no cost) to the running total and hard-stops the
# whole script if MAX_TOTAL_COST_USD is exceeded.
query_triggers_skill() {
  local skill="$1" query="$2"
  local sandbox fifo pid line type tool matched_skill triggered=1 cost=0

  sandbox=$(mktemp -d "${TMPDIR:-/tmp}/skill-eval-sandbox.XXXXXX")
  fifo=$(mktemp -u "${TMPDIR:-/tmp}/skill-eval-fifo.XXXXXX")
  mkfifo "$fifo"
  (cd "$sandbox" && claude -p "$query" \
    --output-format stream-json --verbose \
    --max-budget-usd "$MAX_COST_PER_QUERY_USD" \
    >"$fifo" 2>/dev/null) &
  pid=$!

  while IFS= read -r line; do
    type=$(jq -r '.type // empty' <<<"$line" 2>/dev/null) || continue
    if [[ "$type" == "result" ]]; then
      cost=$(jq -r '.total_cost_usd // 0' <<<"$line" 2>/dev/null)
      break
    fi
    [[ "$type" == "assistant" ]] || continue
    tool=$(jq -r '.message.content[]? | select(.type=="tool_use") | .name' <<<"$line" 2>/dev/null | head -1)
    [[ -n "$tool" ]] || continue
    if [[ "$tool" == "Skill" ]]; then
      matched_skill=$(jq -r '.message.content[]? | select(.type=="tool_use") | .input.skill // empty' <<<"$line" 2>/dev/null)
      [[ "$matched_skill" == "$skill" ]] && triggered=0
      break
    fi
    if [[ "$SAFE_EVAL_TOOLS" != *" $tool "* ]]; then
      break
    fi
  done < "$fifo"

  kill "$pid" >/dev/null 2>&1 || true
  wait "$pid" 2>/dev/null || true
  rm -f "$fifo"
  rm -rf "$sandbox"

  TOTAL_COST_USD=$(echo "${TOTAL_COST_USD:-0} + ${cost:-0}" | bc -l)
  if (( $(echo "$TOTAL_COST_USD > $MAX_TOTAL_COST_USD" | bc -l) )); then
    log "FAIL" "cost cap reached: spent \$$TOTAL_COST_USD of \$$MAX_TOTAL_COST_USD, stopping"
    exit 1
  fi

  return "$triggered"
}

# Scores a query set. Writes {query,should_trigger,trigger_rate,pass} per
# line to stdout as JSON, one object per query.
score_set() {
  local skill="$1" set_file="$2"
  local count i query should_trigger hits run
  count=$(jq 'length' "$set_file")
  for ((i = 0; i < count; i++)); do
    query=$(jq -r ".[$i].query" "$set_file")
    should_trigger=$(jq -r ".[$i].should_trigger" "$set_file")
    hits=0
    for ((run = 0; run < RUNS; run++)); do
      if query_triggers_skill "$skill" "$query"; then
        hits=$((hits + 1))
      fi
    done
    jq -n --arg q "$query" --argjson st "$should_trigger" --argjson hits "$hits" --argjson runs "$RUNS" --arg thr "$THRESHOLD" '
      ($hits / $runs) as $rate
      | { query: $q, should_trigger: $st, trigger_rate: $rate,
          pass: (if $st then $rate > ($thr|tonumber) else $rate <= ($thr|tonumber) end) }'
  done | jq -s '.'
}

split_queries() {
  # Deterministic 60/40 split, proportional within should_trigger:true and
  # should_trigger:false, on the order the queries were written in.
  local queries_file="$1" train_out="$2" val_out="$3"
  jq -c '
    def part(f): (length * f | floor) as $n | .[0:$n];
    def rest(f): (length * f | floor) as $n | .[$n:];
    (map(select(.should_trigger))) as $pos
    | (map(select(.should_trigger|not))) as $neg
    | (($pos|part(0.6)) + ($neg|part(0.6)))
  ' "$queries_file" > "$train_out"
  jq -c '
    def part(f): (length * f | floor) as $n | .[0:$n];
    def rest(f): (length * f | floor) as $n | .[$n:];
    (map(select(.should_trigger))) as $pos
    | (map(select(.should_trigger|not))) as $neg
    | (($pos|rest(0.6)) + ($neg|rest(0.6)))
  ' "$queries_file" > "$val_out"
}

pass_rate() {
  jq '
    (length) as $total
    | ([.[] | select(.pass)] | length) as $passed
    | if $total == 0 then 0 else $passed / $total end
  ' 2>/dev/null
}

optimize_skill() {
  local name="$1"
  local skill_md="skills/$name/SKILL.md"
  local queries_file="$EVAL_DIR/$name.json"
  local run_dir="$RUNS_DIR/$name"
  local train_file val_file

  if [[ ! -f "$skill_md" ]]; then
    log "FAIL" "$name: no skills/$name/SKILL.md"
    return 1
  fi
  if grep -q '^disable-model-invocation: *true' "$skill_md"; then
    log ".." "$name: disable-model-invocation is true, not model-triggered, skipping"
    return 0
  fi
  if [[ ! -f "$queries_file" ]]; then
    log "FAIL" "$name: no $queries_file -- write eval queries first, see $EVAL_DIR/README.md"
    return 1
  fi

  mkdir -p "$run_dir"
  train_file="$run_dir/train.json"
  val_file="$run_dir/validation.json"
  split_queries "$queries_file" "$train_file" "$val_file"

  local iteration=0 best_rate=-1 best_desc="" desc train_scores val_scores train_rate val_rate
  desc=$(get_description "$skill_md")

  while :; do
    log ".." "$name: iteration $iteration, scoring train set"
    train_scores=$(score_set "$name" "$train_file")
    train_rate=$(echo "$train_scores" | pass_rate)
    log ".." "$name: iteration $iteration, scoring validation set"
    val_scores=$(score_set "$name" "$val_file")
    val_rate=$(echo "$val_scores" | pass_rate)
    log "OK" "$name: iteration $iteration -- train pass $train_rate, validation pass $val_rate"

    echo "$val_scores" > "$run_dir/iteration-$iteration.validation.json"
    echo "$train_scores" > "$run_dir/iteration-$iteration.train.json"
    printf '%s\n' "$desc" > "$run_dir/iteration-$iteration.description.txt"

    if (( $(echo "$val_rate > $best_rate" | bc -l) )); then
      best_rate="$val_rate"
      best_desc="$desc"
    fi

    if [[ "$EVAL_ONLY" == "1" ]]; then break; fi
    if (( $(echo "$train_rate >= 1.0" | bc -l) )); then break; fi
    if (( iteration + 1 >= MAX_ITERATIONS )); then break; fi

    local failures
    failures=$(echo "$train_scores" | jq -c '[.[] | select(.pass|not)]')
    if [[ "$(echo "$failures" | jq 'length')" == "0" ]]; then break; fi

    log ".." "$name: iteration $iteration, revising description from $(echo "$failures" | jq 'length') train failure(s)"
    desc=$(revise_description "$skill_md" "$desc" "$failures")
    set_description "$skill_md" "$desc"
    iteration=$((iteration + 1))
  done

  set_description "$skill_md" "$best_desc"
  log "OK" "$name: kept the iteration with the best validation pass rate ($best_rate)"
  log ".." "$name: full history in $run_dir"
}

revise_description() {
  local skill_md="$1" current_desc="$2" failures_json="$3"
  local prompt
  prompt=$(cat <<PROMPT
Revise the "description" frontmatter field of this Claude Code skill so it
triggers more accurately. Rules, from
https://agentskills.io/skill-creation/optimizing-descriptions :

- Imperative: describe when to use the skill, not what it does internally.
- Describe user intent, not implementation.
- Be explicit about scope, including cases where the user does not name
  the domain directly.
- State what the skill does NOT cover if that boundary is being confused
  with something else.
- Do not add specific keywords lifted from the failing queries below --
  that overfits. Find the general pattern they represent instead.
- 1024 characters is a hard limit the spec enforces, not a target. Keep it
  as short as covers the scope. Prefer one or two sentences over a
  paragraph; only go longer if the boundary against a neighboring skill
  genuinely needs the extra words.
- Output ONLY the new description text. No quotes, no preamble, no markdown.

Full skill file for context:
$(cat "$skill_md")

Current description:
$current_desc

Train-set queries this description got wrong (should_trigger is what the
correct behavior is; a should_trigger:true query that did not trigger is a
miss, a should_trigger:false query that did trigger is a false positive):
$failures_json
PROMPT
)
  claude -p "$prompt" --output-format json 2>/dev/null | jq -r '.result'
}

mkdir -p "$RUNS_DIR"
if [[ -n "${1:-}" ]]; then
  optimize_skill "$1"
else
  for dir in skills/*/; do
    optimize_skill "$(basename "$dir")"
  done
fi
