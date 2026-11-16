import json
import pathlib
import subprocess
import sys
import unittest

HOOK = (
    pathlib.Path(__file__).resolve().parent.parent
    / "dot_claude"
    / "hooks"
    / "executable_bash-guard.py"
)

# Each command is a form Claude Code's prefix deny rules miss or a form they already
# catch; the hook must block every one of them.
COMMANDS_TO_BLOCK = {
    "plain_push": "git push",
    "push_with_repo_option": "git -C /some/repo push",
    "push_with_config_option": "git -c push.default=current push origin main",
    "push_with_git_dir_option": "git --git-dir=/some/repo/.git push",
    "push_after_cd": "cd /some/repo && git push",
    "push_after_assignment": "GIT_TRACE=1 git push",
    "push_through_env": "env GIT_TRACE=1 git push",
    "push_through_timeout": "timeout 10 git push",
    "push_in_pipeline": "true | git push",
    "push_in_bash_c": "bash -c 'git -C /some/repo push'",
    "push_in_sh_c_with_combined_flags": "sh -ec 'git push'",
    "push_in_eval": "eval 'git push'",
    "push_in_command_substitution": "echo $(git push)",
    "push_in_backticks": "echo `git push`",
    "push_in_subshell": "(cd /some/repo; git push)",
    "push_in_heredoc_to_shell": "bash <<'EOF'\ngit push\nEOF",
    "push_in_for_loop": 'for repo in a b; do git -C "$repo" push; done',
    "push_in_if_body": "if true; then git push; fi",
    "push_in_brace_group": "{ git push; }",
    "push_after_negation": "! git push",
    "push_through_find_exec": "find . -maxdepth 1 -name .git -execdir git push \\;",
    "push_through_xargs": "printf '%s\\n' a b | xargs -I{} git -C {} push",
    "sudo": "sudo ls",
    "sudo_by_path": "/usr/bin/sudo ls",
    "sudo_through_env": "env sudo ls",
    "sudo_through_command": "command sudo ls",
    "rm_rf": "rm -rf build",
    "rm_fr": "rm -fr build",
    "rm_separate_flags": "rm -r -f build",
    "rm_capital_r": "rm -Rf build",
    "rm_long_flags": "rm --recursive --force build",
    "rm_through_command": "command rm -rf build",
    "unbalanced_quote": "echo 'unterminated",
}

# Each command mentions a blocked word without running the blocked action, so blocking
# it would interrupt ordinary work.
COMMANDS_TO_ALLOW = {
    "commit_subject_mentioning_push": "git commit -m 'Refuse to push images not built from HEAD'",
    "status_with_repo_option": "git -C /some/repo status",
    "log_grepping_push": "git log --grep push",
    "push_as_branch_name": "git checkout push",
    "rm_recursive_only": "rm -r build",
    "rm_force_only": "rm -f build.log",
    "rm_file_named_like_flags": "rm -- -rf",
    "echo_sudo": "echo sudo",
    "grep_for_rm_rf": "grep -rn 'rm -rf' .",
    "heredoc_data_with_apostrophe_and_push": (
        "cat <<'EOF' > notes.txt\ndon't run git push here\nEOF"
    ),
    "printf_push_in_string": "printf '%s\\n' 'git push'",
    "commit_with_heredoc_message_mentioning_push": (
        "git commit -m \"$(cat <<'EOF'\nStop the push (it's unsafe)\nEOF\n)\""
    ),
    "status_with_redirections": "git status 2>&1 >/dev/null",
    "find_exec_without_denied_command": "find . -name '*.sh' -exec shellcheck {} +",
}


def run_hook(command):
    event = {
        "hook_event_name": "PreToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": command},
    }
    return subprocess.run(
        [sys.executable, "-I", str(HOOK)],
        input=json.dumps(event),
        capture_output=True,
        text=True,
        check=False,
    )


class BashGuardTest(unittest.TestCase):
    def test_blocks_denied_commands_however_they_are_written(self):
        for role, command in COMMANDS_TO_BLOCK.items():
            with self.subTest(role=role):
                result = run_hook(command)
                # Python also exits 2 when it cannot open the script, so the prefix shows
                # that the hook itself made the decision and gave Claude a reason.
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertTrue(result.stderr.startswith("bash-guard: "), result.stderr)

    def test_allows_commands_that_only_mention_denied_words(self):
        for role, command in COMMANDS_TO_ALLOW.items():
            with self.subTest(role=role):
                result = run_hook(command)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_blocks_input_that_is_not_a_bash_event(self):
        result = subprocess.run(
            [sys.executable, "-I", str(HOOK)],
            input="not json",
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertTrue(result.stderr.startswith("bash-guard: "), result.stderr)


if __name__ == "__main__":
    unittest.main()
