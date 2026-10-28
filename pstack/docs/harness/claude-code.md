# pstack in Claude Code

pstack skills use Cursor names. In Claude Code, read this file once per session, then map each Cursor name in a skill with the tables below. `<pstack>` means the folder that holds `skills/` and `docs/`. If a Cursor field has no row, drop it and say so. Never pass a field or value the tool schema rejects.

## Tools

| Cursor | Claude Code |
| --- | --- |
| `Task` | `Agent` |
| `AskQuestion` | `AskUserQuestion`. In `-p` mode it is absent, so ask in plain text. |
| Open a todolist | Use `TodoWrite` if the session offers it. Otherwise keep the list in your reply and update it at each phase. |
| Run another pstack skill (`/name` or "the **name** skill") | `Read` `<pstack>/skills/<name>/SKILL.md` and follow it. The `Skill` tool refuses most pstack skills. When you tell the user to type it, write `/pstack:<name>`. |
| `Grep`, `Glob` | `Bash` with `rg` when the session has no `Grep` or `Glob`. |

## Subagent fields

| Cursor | Claude Code |
| --- | --- |
| `subagent_type: generalPurpose` | `subagent_type: "general-purpose"` |
| `poteto-agent`, `comment-sicko` | `pstack:poteto-agent`, `pstack:comment-sicko` |
| `readonly: true` | `subagent_type: "Explore"`. It keeps `Bash`, so the brief also says "do not edit files", and you check `git status` afterward. |
| `readonly: false` | `general-purpose`. It keeps the session's MCP servers. |
| `environment: "cloud"` | `isolation: "worktree"`. Name the branch or commit the worker checks out. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | Omit. Subagents run in the background by default and notify you when they finish. |
| `resume` | Spawn a new agent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

| Cursor | Claude Code |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]`, such as `claude-opus-5-5-xhigh` | `model: "opus"` and `effort: "xhigh"`. `model` takes only `opus`, `sonnet`, `haiku`, `fable`. Drop `-fast`. |
| A `grok-*`, `gpt-*`, or other non-Claude slug | Omit `model` so the agent runs on the session model, and say so. |
| `auto` or `inherit-parent` | Omit `model`. |
| The `pstack-models.mdc` rule, `~/.cursor/rules/pstack-models.mdc` | `~/.claude/rules/pstack-models.md`. Claude Code loads it into every new session, so its role lines are already in context. If they are not, read the file. If the file or the role's line is missing, use the skill's default slug. |
| A role value `<model> <effort>`, such as `opus high` | `model: "opus"` and `effort: "high"`. |
| A role value `claude <model> <effort> via herdr` | A Claude agent in a Herdr pane. See Herdr subagents. |
| A role value `codex via herdr` | A Codex agent in a Herdr pane, on the model the rule's `# codex model:` line names, starting at the `# budget` effort. It counts as a non-Claude family for cross-judging. See Herdr subagents. |

## Herdr subagents

[Herdr](https://github.com/herdrdev/herdr) runs each agent in its own terminal pane, so the operator can watch every one and a non-Claude family such as Codex can take a role. Use it in place of `Agent` when `HERDR_ENV` is `1` and the role's value ends in `via herdr`. When `HERDR_ENV` is not `1`, fall back to `Agent` with the role's model and effort (omit `model` for a Codex role) and say so.

| Step | Command |
| --- | --- |
| Start a Claude agent | `herdr agent start <name> --kind claude --pane <pane> -- --model <model> --effort <effort>` |
| Start a Codex agent | `herdr agent start <name> --kind codex --pane <pane> -- -m <model> -c model_reasoning_effort=<effort>` |
| Brief it | `herdr agent prompt <name> "<brief>"`. Put a long brief in a file and send its path. |
| Read its result | `herdr agent read <name> --source recent-unwrapped --lines <n>` |
| Check its state | `herdr agent get <name>` |

Name the model and effort in your reply for every agent you start. Always pass Codex its model and effort. Without them it runs on `~/.codex/config.toml`, not the role's budget. If Codex refuses the model because of a config feature, such as `Daybreak is unavailable for model <model>`, turn that feature off for that start with `-c <feature>=false`, and never edit the user's Codex config. Close a startup notice that waits for input with `herdr agent send-keys <name> esc`, and change no account setting.

**Lay out one tab per PR.** The operator has to read every pane, and splitting one tab again and again leaves panes too small to read.

- Never split the coordinator's pane. It keeps its own tab.
- Create a PR's tab when its first agent starts, labelled with the issue key or topic: `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --label <label> --cwd <repo> --no-focus`. Its root pane (`.result.root_pane.pane_id`) hosts the owner.
- Keep at most three panes in a tab. The owner takes the left column at full height. Its helpers and verifier lanes share a right column of at most two panes: `herdr pane split --pane <owner-pane> --direction right --no-focus` once, then `herdr pane split --pane <right-pane> --direction down --no-focus` once. When both are busy, wait, or close a finished pane and reuse its slot.
- An agent inside a PR tab starts its helpers only in that tab's right column (`$HERDR_TAB_ID`).
- Work that is not a PR gets its own tab under the same limit.
- Close a pane once its result is read, and a PR's tab once the PR is handed off and nothing in it runs. Close only panes and tabs that you or your agents created.
- Move a live agent with `herdr pane move <pane> --tab <tab> --split right|down --target-pane <pane> --no-focus`, or `--new-tab --label <label>`. The name follows the agent, but the pane ID changes, so read the new one from `.result.move_result.pane.pane_id`.

**Wait on side effects, not on `herdr agent wait`.** It returns early when an agent sits on its own background monitor, which looks the same as a finished turn. Have each owner keep a status file with `- state:` and `- head:` lines, and wait with `<pstack>/skills/poteto-mode/scripts/wait-report.sh`. Take the file's fingerprint with `--fingerprint` before you prompt the owner, then run `wait-report.sh <agent> <file> "<fingerprint>"` in the background. It returns once those lines change and the agent is idle, or as soon as the agent is blocked or gone.

## setup-pstack

Claude Code loads every `.md` file in `~/.claude/rules/` into each new session, so `setup-pstack` writes its rule there. Follow its steps with these changes:

- Detect. The detected models are the `model` values that the `Agent` tool schema lists, each with an effort from its `effort` values. Write a real model as `<model> <effort>`, such as `opus xhigh`. The effort is the last token, so the budget step works as written.
- Defaults. Map each default slug with the rows above: `claude-opus-5-5-xhigh` is `opus xhigh`, and `grok-4.7-xhigh-fast` is `inherit-parent`.
- Herdr. When `HERDR_ENV` is `1`, offer to run roles through Herdr. On yes, write a Claude role as `claude <model> <effort> via herdr` and a role you give to Codex as `codex via herdr`, and add a `# codex model: <model>` comment line. How to start and lay out these agents lives in Herdr subagents above, so the rule holds only the role lines.
- Write. Write `~/.claude/rules/pstack-models.md` with no frontmatter, then the comment lines, the `# budget` line, and one line per role from step 5. Overwrite the whole file. Never put the role lines in `CLAUDE.md` or `AGENTS.md`.

## Paths

| Cursor | Claude Code |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.claude/skills/`, `~/.claude/skills/` |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `~/.claude/plugins/`, `.claude-plugin/plugin.json` |
| `.cursor/rules/*.mdc`, always-applied rules | `CLAUDE.md`, or `AGENTS.md` when no `CLAUDE.md` exists. Claude Code never reads `.mdc` files. The model rule is the exception. See Models. |
| `https://github.com/cursor/plugins/blob/main/pstack/<path>` | `<pstack>/<path>` when that file exists. The plugin ships the skills, `docs/guide/`, and `README.md`. Read the local copy and never fetch it. Give the user the URL when they need a link. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/<session>.jsonl`. The slug is the workspace path with each `/` and `.` changed to `-`, so `/Users/you/proj` is `-Users-you-proj`. The newest `.jsonl` directly in that folder is the current session. Its `<session>/subagents/` folder holds subagent transcripts. Read only this workspace's folder. |

## Cursor-only features

Claude Code has no Cursor Automations, Bugbot, Cursor cloud agents, or built-in PR tool. When a step needs one, put one line in your reply, `Skipped in Claude Code: <step>. <reason>.`, then go on to the next step. Do not stop, ask, or retry. When a later step needs what the skipped step made, such as a URL or a key, leave a placeholder and name it in the line.

| Cursor | Claude Code |
| --- | --- |
| Cursor Automations: routines, `update_state` routine calls, `api2.cursor.sh/automations` webhooks, routine wakes, and `SendToUser` secret requests | Skip with the line. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads, so triage them with the forge command that the step gives. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check or comment. |
| Cursor cloud agents | `environment: "cloud"` maps to a worktree, as in Subagent fields. Skip a step that needs the cloud agent itself, such as its dashboard status or its own machine. |
| A built-in PR tool | Use the forge command that the step gives, such as `gh pr create`. That is not a skip, so write no line. |
