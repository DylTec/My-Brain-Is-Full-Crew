---
name: obsidian-cli
description: >
  Use the official Obsidian CLI to move/rename notes (with automatic link updates),
  search vault content, inspect backlinks/orphans/unresolved links, and manage
  properties/tags/tasks. Prefer this over raw filesystem moves and Grep when
  Obsidian is running. Triggers:
  EN: "obsidian cli", "use obsidian cli", "move with obsidian", "rename with obsidian",
  "obsidian search", "cli search the vault", "update links with obsidian".
  IT: "obsidian cli", "usa obsidian cli", "sposta con obsidian", "rinomina con obsidian",
  "cerca con obsidian".
  FR: "obsidian cli", "utiliser obsidian cli", "déplacer avec obsidian", "chercher avec obsidian".
  ES: "obsidian cli", "usar obsidian cli", "mover con obsidian", "buscar con obsidian".
  DE: "obsidian cli", "obsidian cli verwenden", "mit obsidian verschieben", "mit obsidian suchen".
  PT: "obsidian cli", "usar obsidian cli", "mover com obsidian", "buscar com obsidian".
---

## Vault Path Resolution

Read `Meta/vault-map.md` (always this literal path) to resolve folder paths. Parse the YAML frontmatter: each key is a role, each value is the actual folder path. Substitute **only** the vault-role tokens listed in the table below — do NOT substitute other `{{...}}` patterns (like `{{date}}`, `{{Name}}`, `{{YYYY}}`, etc.), which are template placeholders.

If vault-map.md is absent: warn the user once — "No vault-map.md found, using default paths" — then use these defaults:

| Token | Default |
|-------|---------|
| `{{inbox}}` | `00-Inbox` |
| `{{projects}}` | `01-Projects` |
| `{{areas}}` | `02-Areas` |
| `{{resources}}` | `03-Resources` |
| `{{archive}}` | `04-Archive` |
| `{{people}}` | `05-People` |
| `{{meetings}}` | `06-Meetings` |
| `{{templates}}` | `Templates` |
| `{{moc}}` | `MOC` |
| `{{meta}}` | `Meta` |

If vault-map.md is present but a role is missing: warn the user — "vault-map.md does not define [role]. What folder should I use?" — and wait for their answer before proceeding.

---

# Obsidian CLI — Vault Operations via Official CLI

Always respond to the user in their language. Match the language the user writes in.

Use the `obsidian` CLI to interact with a running Obsidian instance. This is the preferred way to move, rename, and search notes because Obsidian updates internal links and respects attachment/plugin hooks.

Full docs: https://help.obsidian.md/cli  
Shared crew protocol: `.platform/references/obsidian-cli.md`  
Setup guide: `My-Brain-Is-Full-Crew/docs/obsidian-cli-setup.md`

---

## Prerequisites & Detection

1. Obsidian **1.12.7+** installer with **Settings → General → Command line interface** enabled.
2. Obsidian app must be running (the first CLI call can launch it).
3. Detect availability once per session:

```bash
command -v obsidian >/dev/null 2>&1 && obsidian version
```

If detection fails: inform the user, point them to `My-Brain-Is-Full-Crew/docs/obsidian-cli-setup.md`, and fall back to filesystem tools (Read/Write/Edit/Glob/Grep) + manual link fixes. Do not invent CLI commands.

---

## Syntax

**Parameters** take a value with `=`. Quote values with spaces:

```bash
obsidian create name="My Note" content="Hello world"
```

**Flags** are boolean switches with no value:

```bash
obsidian create name="My Note" silent overwrite
```

For multiline content use `\n` for newline and `\t` for tab.

### File targeting

- `file=<name>` — resolves like a wikilink (name only, no path or extension needed)
- `path=<path>` — exact path from vault root, e.g. `00-Inbox/note.md`

Without either, the active file is used.

### Vault targeting

If the shell cwd is inside the vault, that vault is used. Otherwise the most recently focused vault is used. Override with `vault=<name>` as the **first** parameter:

```bash
obsidian vault="My Vault" search query="test"
```

Run `obsidian help` (or `obsidian help <command>`) for the live command list.

---

## Preferred Operations for the Crew

### Move / rename (ALWAYS prefer CLI)

Filesystem `mv` breaks wikilinks and can mishandle attachments. Prefer:

```bash
obsidian move path="00-Inbox/Note.md" to="01-Projects/Alpha/"
obsidian move path="01-Projects/Alpha/Old Name.md" to="01-Projects/Alpha/New Name.md"
obsidian rename path="01-Projects/Alpha/Note.md" name="Better Title"
```

`move` and `rename` update internal links when that setting is enabled in Obsidian.

**Never** use permanent `delete` unless the user explicitly confirms. Prefer trash (default) or archive via `move` to `{{archive}}/`.

### Search (prefer CLI over Grep when available)

```bash
obsidian search query="meeting notes" limit=20
obsidian search:context query="deadline" path="01-Projects" limit=20
```

### Links & vault health

```bash
obsidian backlinks file="My Note"
obsidian unresolved counts verbose
obsidian orphans total
obsidian deadends total
obsidian links file="My Note"
```

### Read / create / append

```bash
obsidian read path="Meta/user-profile.md"
obsidian create name="New Note" path="00-Inbox/New Note.md" content="# Hello" silent
obsidian append path="00-Inbox/New Note.md" content="\n- follow-up"
```

### Properties, tags, tasks

```bash
obsidian property:set name="status" value="done" path="01-Projects/Alpha/Note.md"
obsidian tags sort=count counts
obsidian tasks daily todo
```

### Daily notes

```bash
obsidian daily:read
obsidian daily:append content="- [ ] New task"
```

---

## Safety Rules

1. **Prefer CLI for structural ops** — move, rename, search, backlinks, unresolved links.
2. **Fall back gracefully** — if Obsidian is not running or `obsidian` is missing, use filesystem tools and say so once.
3. **No destructive deletes** — never pass `permanent` unless the user confirms.
4. **Quote paths** — always quote values that contain spaces or special characters.
5. **Stay in the vault** — use `path=` relative to the vault root; resolve role folders via vault-map tokens first.
6. **Silent by default for automation** — use `silent` on create/open flows when you do not need Obsidian to focus the note.
7. **Do not shell-inject note content** — pass content as a single quoted `content=` argument; avoid interpolating untrusted text into broader shell pipelines.

---

## When to Suggest Another Agent

This skill is an operations layer. After CLI work, suggest follow-ups when needed:

- **Sorter / `/inbox-triage`** — notes still need classification after a bulk move
- **Librarian / `/vault-audit`** — unresolved links or orphans remain after renames
- **Connector** — batch of moved notes should be re-cross-linked
- **Architect** — destination folder structure is missing

```markdown
### Suggested next agent
- **Agent**: librarian
- **Reason**: After CLI renames, unresolved links remain
- **Context**: Ran `obsidian unresolved counts`; {{N}} links still broken in {{areas}}/
```

---

## Plugin / theme development (optional)

Only when the user is developing an Obsidian plugin or theme:

```bash
obsidian plugin:reload id=my-plugin
obsidian dev:errors
obsidian dev:screenshot path=screenshot.png
obsidian eval code="app.vault.getFiles().length"
```
