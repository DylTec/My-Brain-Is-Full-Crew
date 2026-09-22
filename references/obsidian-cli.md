# Obsidian CLI Protocol

Shared rules for every agent and skill that reads, moves, renames, or searches vault notes.

Official docs: https://help.obsidian.md/cli  
Crew skill: `.platform/skills/obsidian-cli/SKILL.md`  
Setup: `My-Brain-Is-Full-Crew/docs/obsidian-cli-setup.md`

---

## Why

Raw filesystem moves (`mv`, Write+Delete) break wikilinks and can ignore attachment rules from the user's Obsidian plugins. Obsidian CLI performs the same operations through Obsidian, so link updates and plugin hooks run correctly — saving tokens and avoiding brittle manual link repair.

---

## Detection (once per session)

```bash
command -v obsidian >/dev/null 2>&1 && obsidian version
```

| Result | Behavior |
|--------|----------|
| Success | Prefer Obsidian CLI for the operations below |
| Failure | Fall back to Read/Write/Edit/Glob/Grep + manual link fixes. Mention the setup guide once if structural ops are needed |

Obsidian must be running (or launchable). CLI requires installer **1.12.7+** with **Settings → General → Command line interface** enabled.

---

## Prefer CLI for

| Operation | Command pattern |
|-----------|-----------------|
| Move note | `obsidian move path="from.md" to="folder/or/new-path.md"` |
| Rename note | `obsidian rename path="note.md" name="New Name"` |
| Full-text search | `obsidian search query="..." limit=20` |
| Search with context | `obsidian search:context query="..." limit=20` |
| Backlinks | `obsidian backlinks file="Note"` |
| Unresolved / orphans | `obsidian unresolved` / `obsidian orphans` |
| Tags / properties | `obsidian tags` / `obsidian property:set` … |

## Keep using filesystem tools for

- Editing note body content (Read + Edit/Write) unless a single append/prepend is enough (`obsidian append` / `obsidian prepend`)
- Creating complex new notes where Write is clearer than `obsidian create`
- When Obsidian CLI is unavailable
- Non-vault files (scripts, agent configs under `.platform/`)

---

## Hard rules

1. **Never** `obsidian delete … permanent` unless the user explicitly confirms permanent deletion. Prefer trash (default) or archive via `move` to `{{archive}}/`.
2. After a CLI move/rename, do **not** spend a full pass rewriting wikilinks unless `obsidian unresolved` still reports problems.
3. Quote all paths and query values.
4. Resolve vault-role tokens (`{{inbox}}`, `{{projects}}`, …) from `Meta/vault-map.md` before building `path=` values.
5. Agents without Bash cannot call the CLI directly — suggest the `/obsidian-cli` skill or an agent that has Bash (`sorter`, `architect`, `librarian`).

---

## Allowed Bash surface (when using CLI)

Only `obsidian …` (plus `command -v obsidian` / `which obsidian` for detection). Do not chain arbitrary shell around note contents.
