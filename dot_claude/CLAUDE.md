# User-Level Preferences

## Implementation

- **Test-First** - When a change affects functional behavior, write tests first and confirm they fail before implementing (except documentation, formatting, and renaming)
- **Update docs** - Update README.md and AGENTS.md when specs change (project instruction files are named AGENTS.md; only this global file stays CLAUDE.md)
- **Generalize docs** - Write generalized instructions instead of highlighting a few cases; reference the source of truth (code, self-documenting tools) instead of duplicating values or lists; don't add notes that are already stated or derivable from listed commands
- **Explicit over generated** - When removing duplication in tables or dispatch lists, extract only the repeated body into a helper and keep the enumeration explicit
- **Project containers, not host tools** - Run Python and other project tooling through the project's container wrappers or Make targets, not host interpreters
- **Shell style** - Assign command substitutions before `readonly`/`local`/`export` (`VAR=$(cmd)` then `readonly VAR`); shared functions return values on stdout; sourced libraries contain no `set` options and are mode 644; branch on exit status with `if OUT=$(cmd); then ...; else STATUS=$?; fi` instead of toggling `set +e`; write function bodies with `{ }` and use a subshell only where needed (e.g. `(cd dir && ...)`)

## Workflow

- **Dialogue first** - Explain the situation and your reasoning in text before presenting plans, questions, or actions, then end the turn and let the user react; use the question tool only after the discussion has narrowed or when the user just wants to pick; when challenged, reassess honestly instead of defending
- **Design discussions** - For design topics, even small naming decisions, lay out alternatives with pros/cons and a recommendation
- **Plan before editing** - Requests to show or explain, and approval of scope, are not permission to edit; present the concrete plan (files, changes, verification) and wait for explicit approval
- **Stop on rejection** - IMPORTANT: When a tool call is rejected, stop; explain the situation and wait for instructions instead of guessing the reason and proceeding differently
- **User commits** - Never run `git commit` or `git push`; for each logical change, implement, verify, stage with `git add`, annotate the diff with the hunk-review skill when a Hunk session is open for the repo, then stop and propose exactly one commit message as a code block `!git commit -m '<subject>'`. "Continue" is not permission to commit. Complete each commit before editing files for the next
- **Commit messages** - One-line subject only (imperative mood in English), with no body or trailers such as Co-Authored-By (this overrides attribution instructions); use precise verbs and state the purpose, not file or target names or the repo a change was ported from; the subject must make sense from this repo's history alone, and a purpose that needs "and" signals separate commits; for security fixes, list the CVE IDs in the subject (e.g. `Upgrade openssl to fix CVE-2026-1111 and CVE-2026-2222`)
- **Sibling repos** - Same-named `tools/` scripts are byte-identical including permissions across sibling repos, and Makefile targets stay alphabetical. Sibling repos with the same stack consult each other as peers, with no parent; AGENTS.md does not name siblings. Before aligning, report differences with the compare-repo skill; after changing a shared file, propose `/rollout-commit` to propagate it
- **Shared changes across siblings** - Before a change that sibling repos with the same stack also need (tool or base image bumps, alignment work), check their `git log` and TODO.md; if one has already made it, reuse its decision and wording unless this repo really differs
- **Standalone wrappers** - Root-level wrappers distributed on their own must not source `tools/` and are excluded from alignment
- **Generic tools/** - `tools/` holds only reusable scripts that run standalone (no project-file reads or new required arguments; duplication is fine); project-specific scripts go in the repo root
- **Review before external publish** - IMPORTANT: Prepare and verify locally, then pause for user review before externally visible actions (creating repos, publishing)

## TODO Management

- **Recording** - Record out-of-scope improvement findings from reviews and discussions as TODO.md items instead of acting on them immediately, unless the user asks to act now; add and report them without separate approval, keeping them out of the current commit: leave them unstaged and propose their commit afterward, or, if TODO.md already has changes for the current commit, add them only after that commit
- **Location** - Record items in the repo where the work will happen
- **Format** - Numbered list in priority order, without checkboxes
- **Items** - One task per item, each self-contained enough to act on later and naming the items it must wait for
- **Completion** - Delete finished items and renumber; delete the file when no items remain

## Response Style

- **Respond in Japanese** - Converse in Japanese, including plan files; for code, comments, commit messages, and docs, match the language already used in the project
- **Short answers OK** - One word answers acceptable when appropriate

## Environment

- **Interactive aliases** - `rm`, `cp`, and `mv` are aliased with `-i` and silently do nothing when the prompt gets EOF; use `command rm`/`command cp`/`command mv` and verify the result
