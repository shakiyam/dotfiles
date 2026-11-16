import os
import pathlib
import subprocess
import tempfile
import unittest

PRECHECK = (
    pathlib.Path(__file__).resolve().parent.parent
    / "dot_claude"
    / "skills"
    / "rollout-commit"
    / "executable_precheck.sh"
)

SHARED_FILE = "tools/shared.sh"
OLD_CONTENT = "echo old\n"
NEW_CONTENT = "echo new\n"


def isolated_env(home):
    # The user's own git and XDG settings must not leak into the repositories or the
    # precheck's configuration lookup.
    env = {key: value for key, value in os.environ.items() if key != "XDG_CONFIG_HOME"}
    env.update(
        HOME=str(home),
        GIT_CONFIG_NOSYSTEM="1",
        GIT_AUTHOR_NAME="test",
        GIT_AUTHOR_EMAIL="test@example.com",
        GIT_COMMITTER_NAME="test",
        GIT_COMMITTER_EMAIL="test@example.com",
    )
    return env


def git(env, repo, *args):
    subprocess.run(["git", "-C", str(repo), *args], env=env, check=True, capture_output=True)


def make_repo(env, path, content):
    (path / "tools").mkdir(parents=True)
    (path / SHARED_FILE).write_text(content)
    git(env, path, "init", "-q")
    git(env, path, "add", ".")
    git(env, path, "commit", "-q", "-m", "Add the shared file")


class RolloutPrecheckTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = pathlib.Path(tmp.name).resolve()
        # The reference and the sibling share a parent; the outsider holds the same file
        # under a different parent, like a repository kept in a tool's data directory.
        self.reference = self.home / "projects" / "reference"
        self.sibling = self.home / "projects" / "sibling"
        self.outsider = self.home / "elsewhere" / "outsider"
        self.env = isolated_env(self.home)
        for repo in (self.reference, self.sibling, self.outsider):
            make_repo(self.env, repo, OLD_CONTENT)
        (self.reference / SHARED_FILE).write_text(NEW_CONTENT)
        git(self.env, self.reference, "commit", "-q", "-am", "Update the shared file")

    def configure(self, *lines, config_home=None):
        config_dir = (config_home or self.home / ".config") / "rollout-commit"
        config_dir.mkdir(parents=True)
        (config_dir / "repositories").write_text("".join(f"{line}\n" for line in lines))

    def run_precheck(self, cwd=None):
        result = subprocess.run(
            ["bash", str(PRECHECK), str(self.reference), "HEAD"],
            cwd=cwd,
            env=self.env,
            capture_output=True,
            text=True,
            check=True,
        )
        return [line.split("\t") for line in result.stdout.splitlines()]

    def listed_repositories(self, cwd=None):
        return [row[0] for row in self.run_precheck(cwd)]

    def test_lists_only_siblings_without_configuration(self):
        self.assertEqual(self.listed_repositories(), [str(self.sibling)])

    def test_adds_configured_repositories_by_full_path(self):
        self.configure("~/elsewhere/*/")
        rows = self.run_precheck()
        self.assertEqual(
            sorted(row[0] for row in rows), sorted([str(self.sibling), str(self.outsider)])
        )
        outsider_row = next(row for row in rows if row[0] == str(self.outsider))
        self.assertEqual(outsider_row[1], "apply")

    def test_lists_a_repository_found_twice_once(self):
        # The pattern matches the sibling that the parent search already finds.
        self.configure("~/projects/*/")
        self.assertEqual(self.listed_repositories(), [str(self.sibling)])

    def test_excludes_the_reference_even_when_configured(self):
        self.configure(str(self.reference))
        self.assertNotIn(str(self.reference), self.listed_repositories())

    def test_skips_blank_and_comment_lines(self):
        self.configure("", "# repositories outside the parent", "~/elsewhere/outsider")
        self.assertEqual(
            sorted(self.listed_repositories()), sorted([str(self.sibling), str(self.outsider)])
        )

    def test_ignores_patterns_that_match_nothing(self):
        # Running from inside the outsider shows that an unmatched pattern does not fall
        # back to the current directory.
        self.configure("~/missing/*/")
        self.assertEqual(self.listed_repositories(cwd=self.outsider), [str(self.sibling)])

    def test_reads_configuration_from_xdg_config_home(self):
        config_home = self.home / "xdg"
        self.configure("~/elsewhere/*/", config_home=config_home)
        self.env["XDG_CONFIG_HOME"] = str(config_home)
        self.assertIn(str(self.outsider), self.listed_repositories())


if __name__ == "__main__":
    unittest.main()
