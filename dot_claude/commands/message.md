---
description: "Generate a commit message from staged changes (git diff --cached)"
allowed-tools: ["Bash"]
---

# Generate Commit Message

Analyze the staged changes and generate an appropriate commit message:

!git diff --cached

Based on the staged changes above, generate a concise commit message that:

1. Starts with a capital verb in present tense, imperative mood (e.g., "Add", "Fix", "Update", "Remove")
2. Focuses on the "why" rather than the "what"
3. Is 1-2 sentences maximum

If no staged changes are found, suggest staging files first with `git add`.
