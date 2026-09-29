#!/usr/bin/env bash
# Trigger-routing evals for skills and for custom agents that appear over time.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

_routing_json() {
  python3 "$ROOT/orchestra/eval-routing" --json "$@"
}

_routing_field() {
  local json="$1" expr="$2"
  python3 -c 'import json,sys; data=json.loads(sys.argv[1]); print(eval(sys.argv[2], {"data": data}))' "$json" "$expr"
}

_write_skill() {
  local dir="$1" name="$2" triggers="$3"
  mkdir -p "$dir/$name"
  cat > "$dir/$name/SKILL.md" <<EOF
---
name: $name
description: >
  Test skill. Triggers:
  $triggers
---
EOF
}

_write_agent() {
  local dir="$1" name="$2" triggers="$3"
  mkdir -p "$dir"
  cat > "$dir/$name.md" <<EOF
---
name: $name
description: >
  Test custom agent. Triggers: $triggers
---
EOF
}

_write_registry() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$path")"
  {
    echo "# Agent Registry"
    echo "| Name | Role | Capabilities | Input | Output | Status |"
    echo "|------|------|-------------|-------|--------|--------|"
    echo "| postman | mail | read | mail | notes | active |"
    echo "<!-- MBIFC:CUSTOM_AGENTS_START -->"
    for row in "$@"; do
      echo "$row"
    done
    echo "<!-- MBIFC:CUSTOM_AGENTS_END -->"
  } > "$path"
}

_write_dispatcher() {
  local path="$1"
  cat > "$path" <<'EOF'
## Skill routing (check FIRST — highest priority)

| # | Skill | Description | Triggers |
|---|-------|-------------|----------|
| 1 | `/inbox-triage` | File notes. | EN: "triage the inbox", "empty inbox" · IT: "smista l'inbox" |
| 2 | `/email-triage` | Read mail. | EN: "check my email" · IT: "controlla le email" |

## 6. SORTER (agent)

Triggers: "batch sort", "priority triage"
EOF
}

test_repo_skill_routing_evals_pass() {
  local out
  out="$(_routing_json --repo "$ROOT")" || { echo "$out"; return 1; }
  [[ "$(_routing_field "$out" "data['ok']")" == "True" ]] || { echo "$out"; return 1; }
  [[ "$(_routing_field "$out" "data['skills']")" == "14" ]] || { echo "$out"; return 1; }
  [[ "$(_routing_field "$out" "data['mode']")" == "repo" ]] || { echo "$out"; return 1; }
}

test_vault_custom_agent_set_changes_as_agents_are_added_and_removed() {
  local vault; vault="$(mktemp -d)"
  _write_skill "$vault/.claude/skills" inbox-triage 'EN: "triage the inbox", "empty inbox". IT: "smista l'"'"'inbox".'
  _write_skill "$vault/.claude/skills" email-triage 'EN: "check my email". IT: "controlla le email".'
  _write_dispatcher "$vault/CLAUDE.md"
  _write_agent "$vault/.claude/agents" budget-tracker '"how much did I spend", "grocery budget", "am I over budget", "spesa di oggi", "budget della settimana", "what did I buy"'
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |"

  local out
  out="$(_routing_json --vault "$vault")" || { echo "$out"; rm -rf "$vault"; return 1; }
  [[ "$(_routing_field "$out" "data['custom_agents']")" == "['budget-tracker']" ]] || { echo "$out"; rm -rf "$vault"; return 1; }

  _write_agent "$vault/.claude/agents" meal-planner '"what should I cook", "piano pasti", "dinner ideas", "pranzo di domani", "lista della spesa", "meal plan"'
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |" \
    "| meal-planner | meals | read | meals | plans | active |"
  out="$(_routing_json --vault "$vault")" || { echo "$out"; rm -rf "$vault"; return 1; }
  [[ "$(_routing_field "$out" "sorted(data['custom_agents'])")" == "['budget-tracker', 'meal-planner']" ]] || { echo "$out"; rm -rf "$vault"; return 1; }

  # A phrase already owned by a skill must not be given to the new agent.
  _write_agent "$vault/.claude/agents" meal-planner '"check my email", "piano pasti", "dinner ideas", "pranzo di domani", "lista della spesa", "meal plan"'
  out="$(_routing_json --vault "$vault")" && { echo "expected collision to fail"; echo "$out"; rm -rf "$vault"; return 1; }
  echo "$out" | grep -q 'check my email' || { echo "collision should name the stolen phrase"; echo "$out"; rm -rf "$vault"; return 1; }

  rm -f "$vault/.claude/agents/meal-planner.md"
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |"
  out="$(_routing_json --vault "$vault")" || { echo "$out"; rm -rf "$vault"; return 1; }
  [[ "$(_routing_field "$out" "data['custom_agents']")" == "['budget-tracker']" ]] || { echo "$out"; rm -rf "$vault"; return 1; }

  rm -rf "$vault"
}

test_vault_rejects_short_trigger_lists_ambiguous_agents_and_disabled_is_skipped() {
  local vault; vault="$(mktemp -d)"
  _write_skill "$vault/.claude/skills" inbox-triage 'EN: "triage the inbox", "empty inbox". IT: "smista l'"'"'inbox".'
  _write_skill "$vault/.claude/skills" email-triage 'EN: "check my email". IT: "controlla le email".'
  _write_dispatcher "$vault/CLAUDE.md"
  _write_agent "$vault/.claude/agents" budget-tracker '"grocery budget", "spesa di oggi"'
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |"

  local out
  out="$(_routing_json --vault "$vault")" && { echo "expected short trigger list to fail"; echo "$out"; rm -rf "$vault"; return 1; }
  echo "$out" | grep -q 'need at least 6' || { echo "$out"; rm -rf "$vault"; return 1; }

  _write_agent "$vault/.claude/agents" budget-tracker '"how much did I spend", "grocery budget", "am I over budget", "spesa di oggi", "budget della settimana", "what did I buy"'
  _write_agent "$vault/.claude/agents" meal-planner '"how much did I spend", "piano pasti", "dinner ideas", "pranzo di domani", "lista della spesa", "meal plan"'
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |" \
    "| meal-planner | meals | read | meals | plans | active |"
  out="$(_routing_json --vault "$vault")" && { echo "expected shared trigger to fail"; echo "$out"; rm -rf "$vault"; return 1; }
  echo "$out" | grep -q 'ambiguous' || { echo "$out"; rm -rf "$vault"; return 1; }

  _write_agent "$vault/.claude/agents" old-tracker '"only one"'
  _write_registry "$vault/.claude/references/agents-registry.md" \
    "| budget-tracker | budgets | read | spending | reports | active |" \
    "| old-tracker | old | read | old | old | disabled |"
  rm -f "$vault/.claude/agents/meal-planner.md"
  out="$(_routing_json --vault "$vault")" || { echo "$out"; rm -rf "$vault"; return 1; }
  [[ "$(_routing_field "$out" "data['custom_agents']")" == "['budget-tracker']" ]] || { echo "$out"; rm -rf "$vault"; return 1; }

  rm -rf "$vault"
}

test_install_routing_evals_copies_fixtures_and_keeps_custom_agent_evals() {
  # shellcheck source=scripts/lib.sh
  source "$ROOT/scripts/lib.sh"
  local vault; vault="$(mktemp -d)"
  local count
  count="$(install_routing_evals "$ROOT" "$vault")"
  [[ "$count" == "14" ]] || { echo "expected 14 skill evals, got $count"; rm -rf "$vault"; return 1; }
  [[ -x "$vault/Meta/scripts/eval-routing" ]] || { echo "runner was not installed"; rm -rf "$vault"; return 1; }
  [[ -f "$vault/Meta/evals/skills/inbox-triage.json" ]] || { echo "inbox-triage fixture missing"; rm -rf "$vault"; return 1; }

  echo stale > "$vault/Meta/evals/skills/gone.json"
  mkdir -p "$vault/Meta/evals/agents"
  echo keep > "$vault/Meta/evals/agents/budget-tracker.json"
  install_routing_evals "$ROOT" "$vault" >/dev/null
  [[ ! -f "$vault/Meta/evals/skills/gone.json" ]] || { echo "stale core fixture was kept"; rm -rf "$vault"; return 1; }
  [[ -f "$vault/Meta/evals/agents/budget-tracker.json" ]] || { echo "custom agent eval was removed"; rm -rf "$vault"; return 1; }
  rm -rf "$vault"
}

test_launchme_installs_evals_that_pass_against_the_vault() {
  local vault; vault="$(mktemp -d)"
  local log; log="$(mktemp)"
  if ! bash "$ROOT/scripts/launchme.sh" --platform claude-code --target "$vault" >"$log" 2>&1; then
    cat "$log"
    rm -rf "$vault" "$log"
    return 1
  fi
  [[ -x "$vault/Meta/scripts/eval-routing" ]] || { echo "launchme did not install eval-routing"; rm -rf "$vault" "$log"; return 1; }
  [[ -f "$vault/Meta/evals/skills/contact-sync.json" ]] || { echo "launchme did not install skill fixtures"; rm -rf "$vault" "$log"; return 1; }

  local out
  if ! out="$(python3 "$vault/Meta/scripts/eval-routing" --json)"; then
    echo "$out"
    rm -rf "$vault" "$log"
    return 1
  fi
  [[ "$(_routing_field "$out" "data['mode']")" == "vault" ]] || { echo "$out"; rm -rf "$vault" "$log"; return 1; }
  [[ "$(_routing_field "$out" "data['skills']")" == "14" ]] || { echo "$out"; rm -rf "$vault" "$log"; return 1; }
  [[ "$(_routing_field "$out" "data['custom_agents']")" == "[]" ]] || { echo "$out"; rm -rf "$vault" "$log"; return 1; }

  rm -f "$vault/Meta/evals/skills/onboarding.json"
  if ! printf 'c\n' | bash "$ROOT/scripts/updateme.sh" --target "$vault" >"$log" 2>&1; then
    cat "$log"
    rm -rf "$vault" "$log"
    return 1
  fi
  [[ -f "$vault/Meta/evals/skills/onboarding.json" ]] || { echo "updateme did not restore skill fixtures"; rm -rf "$vault" "$log"; return 1; }
  rm -rf "$vault" "$log"
}
