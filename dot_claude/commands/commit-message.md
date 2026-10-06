---
description: "Generate a commit message from staged changes (git diff --cached)"
---

# Generate Commit Message from Staged Changes

First, run `git diff --cached` using the Bash tool.
If there are no staged changes, simply state "No staged changes found."

Based ONLY on the diff output, generate a concise commit message that:

1. Starts with a capital verb in present tense, imperative mood (e.g., "Add", "Fix", "Update", "Remove")
2. Focuses on the "why" rather than the "what", but ONLY infer intent from what is clearly visible in the diff
3. Is a single line with no body, preferably under 50 characters
4. Do NOT search for additional files or context beyond the diff
