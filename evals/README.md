# Skill routing evals

Skills are selected from the `description` in `SKILL.md` and from the dispatcher routing table. If those lists drift, a phrase the user expects can fail to trigger the skill.

`orchestra/eval-routing` checks the lists without calling a model:

- every double-quoted trigger in a skill description is also in the dispatcher row, and the reverse
- every trigger phrase routes to that skill, including when the phrase sits inside a longer sentence
- near-miss phrases in `evals/cross-routing.json` route to the other skill or agent
- each `evals/skills/<name>.json` file has a `query`, `files`, and at least three `expected_behavior` entries (the rubric from Anthropic's skill eval guidance) plus at least three `routing` queries

```bash
python3 orchestra/eval-routing
```

The installer copies the runner to `Meta/scripts/eval-routing` and the skill fixtures to `Meta/evals/skills/`. In a vault the command also reads every active custom agent. Adding or removing an agent changes the route table on the next run. A custom agent needs:

- an active row in `agents-registry.md`
- at least six double-quoted trigger phrases in its description
- a `Meta/evals/agents/<name>.json` file written by `/create-agent` (optional extra queries; the description phrases are always checked)
- phrases that are not already owned by a skill or another agent

`/create-agent` and `/manage-agent` write that eval file and run the command before they report success.
