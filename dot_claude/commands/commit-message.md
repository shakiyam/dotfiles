---
description: "Generate a commit message from staged changes (git diff --cached)"
---

# Generate Commit Message from Staged Changes

First, run `git diff --cached` using the Bash tool.
If there are no staged changes, simply state "No staged changes found."

Generate a commit message that follows the 「コミット・メッセージ」 rules in CLAUDE.md.
Infer intent only from the diff and from what the user has stated in this conversation; do NOT search for additional files or context, except the past commit subjects that the 「コミット・メッセージ」 rules ask you to check.
If a rule needs information that is not available there (such as CVE IDs), ask the user instead of guessing.
