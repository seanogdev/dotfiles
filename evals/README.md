# Skill evals

Eval fixtures for this repo's personal skills under `skills/<name>/`.
Excluded from stow (`/evals` in `.stow-local-ignore`) since this is
repo-local dev tooling, not something that belongs in `$HOME`.

Two kinds, per <https://agentskills.io>:

- `descriptions/` -- trigger evals. Does the skill's `description` field
  activate on the right prompts and stay quiet on the wrong ones? See
  <https://agentskills.io/skill-creation/optimizing-descriptions>.
- `contents/` -- output-quality evals. Given the skill triggers, does it
  produce a good result? See
  <https://agentskills.io/skill-creation/evaluating-skills>. Not built yet.

`_scripts/optimize-skill-descriptions.sh` runs the `descriptions/` evals
and the description-optimization loop. Run history and scores land in
`evals/.runs/` (gitignored).
