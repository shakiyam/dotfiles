# User-Level Preferences

## Implementation

- **Test-First** - Ask "Does this change functional behavior?" If YES → Write tests FIRST, confirm they fail, then implement. (Exceptions: documentation, formatting, renaming)
- **Incremental changes** - Make small, verifiable steps
- **Run tests** - Verify behavior after changes
- **Update docs** - Update README.md and CLAUDE.md when specs change or explicitly requested
- **Generalize docs** - Write generalized instructions instead of highlighting a few cases; reference the source of truth (code, self-documenting tools) instead of duplicating values or lists

## Workflow

- **Dialogue first** - Explain the situation and your reasoning in text before presenting plans, questions, or actions; for design topics, deepen the discussion before converging on a plan
- **Stop on rejection** - IMPORTANT: When a tool call is rejected, stop; explain the situation and wait for instructions instead of guessing the reason and proceeding differently
- **One commit at a time** - When work is split into commits, complete each commit before editing files for the next
- **Review before external publish** - IMPORTANT: Prepare and verify locally, then pause for user review before externally visible actions (creating repos, pushing, publishing)

## Response Style

- **Respond in Japanese** - Converse in Japanese; for code, comments, commit messages, and docs, match the language already used in the project
- **Short answers OK** - One word answers acceptable when appropriate
