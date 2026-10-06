# User-Level Preferences

## Implementation

- **Test-First** - Ask "Does this change functional behavior?" If YES → Write tests FIRST, confirm they fail, then implement. (Exceptions: documentation, formatting, renaming)
- **Incremental changes** - Make small, verifiable steps
- **Run tests** - Verify behavior after changes
- **Update docs** - Update README.md and CLAUDE.md when specs change or explicitly requested
- **Generalize docs** - Write generalized instructions instead of highlighting a few cases; reference the source of truth (code, self-documenting tools) instead of duplicating values or lists; don't add notes that are already stated or derivable from listed commands
- **Explicit over generated** - When removing duplication in tables or dispatch lists, extract only the repeated body into a helper and keep the enumeration explicit
- **Project containers, not host tools** - Run Python and other project tooling through the project's container wrappers or Make targets, not host interpreters
- **Shell style** - Assign command substitutions before `readonly`/`local`/`export` (`VAR=$(cmd)` then `readonly VAR`); shared functions return values on stdout; sourced libraries contain no `set` options and are mode 644

## Workflow

- **Dialogue first** - Explain the situation and your reasoning in text before presenting plans, questions, or actions, then end the turn and let the user react; use the question tool only after the discussion has narrowed or when the user just wants to pick. For design topics, even small naming decisions, lay out alternatives with pros/cons and a recommendation; when challenged, reassess honestly instead of defending
- **Plan before editing** - Requests to show or explain, and approval of scope, are not permission to edit; present the concrete plan (files, changes, verification) and wait for explicit approval
- **Stop on rejection** - IMPORTANT: When a tool call is rejected, stop; explain the situation and wait for instructions instead of guessing the reason and proceeding differently
- **User commits** - Never run `git commit` or `git push`; for each logical change, implement, verify, stage with `git add`, then stop and propose the commit message. "Continue" is not permission to commit. Complete each commit before editing files for the next
- **Commit messages** - One-line English imperative subject only, with no body or trailers such as Co-Authored-By (this overrides attribution instructions); use precise verbs and state the purpose, not file or target names or the repo a change was ported from
- **TODO.md** - Numbered list in priority order (no checkboxes), each item self-contained enough to act on later; delete finished items and renumber; record items in the repo where the work will happen
- **Sibling repos follow ../bbs** - In repos whose `tools/` mirrors `../bbs/tools/`, `../bbs` is the reference for `tools/`, Makefile, and workflows: keep same-named tool scripts byte-identical including permissions, and keep Makefile targets alphabetical. Before changing, report differences classified as (a) should align, (b) legitimately project-specific, (c) optional improvements; when this repo is ahead of bbs, report a back-port candidate instead of overwriting
- **Review before external publish** - IMPORTANT: Prepare and verify locally, then pause for user review before externally visible actions (creating repos, publishing)

## Response Style

- **Respond in Japanese** - Converse in Japanese; for code, comments, commit messages, and docs, match the language already used in the project
- **Short answers OK** - One word answers acceptable when appropriate

## Environment

- **Interactive aliases** - `rm`, `cp`, and `mv` are aliased with `-i` and silently do nothing when the prompt gets EOF; use `command rm`/`command cp`/`command mv` and verify the result
