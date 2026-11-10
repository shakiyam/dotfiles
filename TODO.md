# TODO

- TODO#1 Decide how commit messages refer to TODO items, and with it how to delete items decided against. Options include prefixing the subject with `TODO#<n>`. The 「コミット・メッセージ」 rule in `dot_claude/CLAUDE.md` requires a subject that makes sense from this repo's history alone, so once an item is deleted its ID alone does not say what it was; a dropped item's subject also needs the reason for dropping it. Then update the 「コミット・メッセージ」 and 「完了」 rules there.
- TODO#2 When starting to use git worktrees, add a worktree workflow to `dot_claude/CLAUDE.md`: a short-lived branch merged with `git merge --ff-only` for medium tasks, `git merge --no-ff` with the decision record in the merge commit for large tasks, and design memos at `docs/design/TODO<n>.md` that are deleted on completion. Wait for TODO#1, since the merge commit message depends on how commit messages refer to items.

Next ID: TODO#3
