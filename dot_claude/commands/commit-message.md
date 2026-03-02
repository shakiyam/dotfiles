---
description: "Generate a commit message from staged changes (git diff --cached)"
---

# Generate Commit Message from Staged Changes

!git diff --cached

Based ONLY on the diff output above, generate a concise commit message that:

1. Starts with a capital verb in present tense, imperative mood (e.g., "Add", "Fix", "Update", "Remove")
2. Focuses on the "why" rather than the "what", but ONLY infer intent from what is clearly visible in the diff
3. Is 1-2 sentences maximum, preferably under 50 characters for the first line
4. Do NOT search for additional files or context beyond the diff shown above

If there are no staged changes, simply state "No staged changes found."
