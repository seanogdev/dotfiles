# Trigger evals

One file per skill: `<skill-name>.json`, a JSON array of:

```json
{ "query": "a realistic user prompt", "should_trigger": true }
```

Aim for 8-10 `should_trigger: true` and 8-10 `should_trigger: false` per
skill. The strongest `false` cases are near-misses: prompts that share
words or domain with the skill but need something else, often the
neighboring skill this one's description says it does not cover.

`_scripts/optimize-skill-descriptions.sh` reads these, splits each file
60/40 into a train and a validation set, and runs the optimization loop
from <https://agentskills.io/skill-creation/optimizing-descriptions>. It
skips any skill whose `SKILL.md` sets `disable-model-invocation: true`,
since those are not triggered by description matching.
