# Setting Up Obsidian CLI

The Crew can use the [official Obsidian CLI](https://help.obsidian.md/cli) for vault operations that are messy or costly over raw filesystem tools — especially **moving/renaming notes** (automatic internal-link updates) and **searching** vault content.

This is **optional**. Without it, agents keep using Read/Write/Edit/Glob/Grep as before. With it, Sorter, Architect, Librarian, Seeker, and the `/obsidian-cli` skill prefer Obsidian for structural ops.

---

## Prerequisites

- **Obsidian installer 1.12.7+** (CLI needs a current installer, not only an in-app update)
- Desktop Obsidian (the app must be able to run; the CLI talks to a running instance)
- Your vault already opened in Obsidian at least once

---

## Enable the CLI

1. Upgrade Obsidian to installer **1.12.7+** (see [installer updates](https://help.obsidian.md/Obsidian/Update+Obsidian)).
2. Open **Settings → General**.
3. Enable **Command line interface**.
4. Follow the prompt to register the `obsidian` command on your PATH.

---

## Verify

With Obsidian open (or able to launch):

```bash
obsidian version
obsidian help
obsidian files total
```

If those succeed, the Crew will auto-detect the CLI on the next session.

---

## What the Crew uses it for

| Task | Why CLI helps |
|------|----------------|
| Move / rename notes during inbox triage or defrag | Updates internal links when that Obsidian setting is on; respects attachment/plugin hooks |
| Search | Native vault search instead of Grep sweeps |
| Link health | `unresolved`, `orphans`, `backlinks` without hand-rolled scans |

Skill entry point: say **"obsidian cli"** or **"move with obsidian"** to invoke `/obsidian-cli`.  
Protocol used by other agents: `.platform/references/obsidian-cli.md` (path varies by platform after install).

---

## Recommended Obsidian settings

- **Settings → Files and links → Automatically update internal links** — keep **on** so `obsidian move` / `obsidian rename` rewrite references for you.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `obsidian: command not found` | Re-enable CLI in Settings → General and ensure the registration step completed; restart the terminal |
| Commands hang / fail while Obsidian is closed | Open Obsidian (first CLI call may launch it); keep the target vault available |
| Wrong vault targeted | Run from inside the vault directory, or pass `vault="Vault Name"` as the first argument |
| Links still broken after move | Confirm "Automatically update internal links" is on; then run `obsidian unresolved counts` |
| Installer too old | Install a fresh Obsidian build from [obsidian.md](https://obsidian.md) (in-app update alone may not ship the CLI) |

More detail: [Obsidian CLI help](https://help.obsidian.md/cli).
