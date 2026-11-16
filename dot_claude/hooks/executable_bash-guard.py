#!/usr/bin/env python3
"""PreToolUse hook that blocks denied Bash commands however they are written.

Claude Code's Bash deny rules match the command text by prefix, so forms such as
`git -C <repo> push`, `rm -fr`, `/usr/bin/sudo`, or `bash -c '...'` slip past them.
This hook parses the command and blocks `git push`, `sudo`, and recursive forced
`rm` wherever they appear. It exits 2 with a reason on stderr to block, and also
when it cannot parse the input, so that a doubtful command is never let through.
It covers the forms Claude writes in ordinary work, not deliberate evasion such
as running a script file or quoting a heredoc marker.

It runs on the host interpreter rather than in a container because Claude Code
starts it before every Bash call, and it uses only the standard library so that
it works on any host with python3.
"""

import json
import os
import re
import shlex
import sys

SEPARATOR_CHARS = set(";&|()\n")
REDIRECTION_CHARS = set("<>")
SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
# Words that start a command inside a compound command, such as `do git push`.
RESERVED_WORDS = {"!", "{", "}", "do", "done", "elif", "else", "fi", "if", "then", "until", "while"}
FIND_ACTIONS = {"-exec", "-execdir", "-ok", "-okdir"}
GIT_OPTIONS_WITH_ARGUMENT = {
    "-C",
    "-c",
    "--git-dir",
    "--work-tree",
    "--namespace",
    "--super-prefix",
    "--config-env",
}
HEREDOC_MARKER = re.compile(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")


class BlockedError(Exception):
    pass


def split_heredocs(text):
    """Return the command lines without heredoc bodies, and the bodies in order."""
    lines = text.split("\n")
    kept, bodies = [], []
    index = 0
    while index < len(lines):
        line = lines[index]
        kept.append(line)
        index += 1
        for strip_tabs, _, delimiter in HEREDOC_MARKER.findall(line):
            body = []
            while index < len(lines):
                candidate = lines[index].lstrip("\t") if strip_tabs else lines[index]
                index += 1
                if candidate == delimiter:
                    break
                body.append(lines[index - 1])
            bodies.append("\n".join(body))
    return "\n".join(kept), bodies


def take_substitutions(text):
    """Replace $(...) and `...` outside single quotes with a word, returning their contents."""
    result, inner = [], []
    index, quote = 0, None
    while index < len(text):
        char = text[index]
        if quote == "'":
            if char == "'":
                quote = None
            result.append(char)
            index += 1
        elif char == "\\" and index + 1 < len(text):
            result.append(text[index : index + 2])
            index += 2
        elif char in "'\"" and quote in (None, char):
            quote = None if quote else char
            result.append(char)
            index += 1
        elif text.startswith("$(", index):
            depth, end = 1, index + 2
            while end < len(text) and depth:
                depth += {"(": 1, ")": -1}.get(text[end], 0)
                end += 1
            if depth:
                raise BlockedError("cannot parse an unterminated command substitution")
            inner.append(text[index + 2 : end - 1])
            result.append("_")
            index = end
        elif char == "`":
            end = text.find("`", index + 1)
            if end < 0:
                raise BlockedError("cannot parse an unterminated backquote")
            inner.append(text[index + 1 : end])
            result.append("_")
            index = end + 1
        else:
            result.append(char)
            index += 1
    if quote:
        raise BlockedError("cannot parse an unterminated quote")
    return "".join(result), inner


def simple_commands(text):
    """Yield (words, redirections) for each simple command."""
    lexer = shlex.shlex(text, posix=True, punctuation_chars=";&|()<>\n")
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError as error:
        raise BlockedError(f"cannot parse the command: {error}") from error
    words, redirections = [], []
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token and set(token) & REDIRECTION_CHARS and set(token) <= REDIRECTION_CHARS | {"&"}:
            target = tokens[index + 1] if index + 1 < len(tokens) else ""
            redirections.append((token, target))
            index += 2
            continue
        if token and set(token) <= SEPARATOR_CHARS:
            if words:
                yield words, redirections
            words, redirections = [], []
        else:
            words.append(token)
        index += 1
    if words:
        yield words, redirections


def strip_wrappers(words):
    """Drop assignments and wrapper commands that run the rest of the words."""
    while words:
        if ASSIGNMENT.match(words[0]):
            words = words[1:]
            continue
        name = os.path.basename(words[0])
        rest = words[1:]
        if words[0] in RESERVED_WORDS:
            words = rest
        elif name in ("command", "builtin"):
            if rest and rest[0] in ("-v", "-V"):
                return []
            words = [word for word in rest if word != "-p"]
        elif name in ("exec", "nohup", "time"):
            words = skip_options(rest, {"-a"})
        elif name == "env":
            words = skip_options(rest, {"-u", "-C", "--unset", "--chdir"})
        elif name == "nice":
            words = skip_options(rest, {"-n", "--adjustment"})
        elif name == "stdbuf":
            words = skip_options(rest, {"-i", "-o", "-e"})
        elif name == "timeout":
            words = skip_options(rest, {"-s", "-k", "--signal", "--kill-after"})[1:]
        elif name == "xargs":
            words = skip_options(rest, {"-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s"})
        else:
            return words
    return words


def skip_options(words, options_with_argument):
    index = 0
    while index < len(words) and words[index].startswith("-") and words[index] != "-":
        if words[index] == "--":
            return words[index + 1 :]
        index += 2 if words[index] in options_with_argument else 1
    return words[index:]


def check_text(text, depth=0):
    if depth > 10:
        raise BlockedError("cannot parse a command nested this deeply")
    text, bodies = split_heredocs(text)
    text, substitutions = take_substitutions(text)
    for inner in substitutions:
        check_text(inner, depth + 1)
    for words, redirections in simple_commands(text):
        stdin_texts = []
        for operator, target in redirections:
            if operator in ("<<", "<<-"):
                stdin_texts.append(bodies.pop(0) if bodies else "")
            elif operator == "<<<":
                stdin_texts.append(target)
        check_words(strip_wrappers(words), stdin_texts, depth)


def check_words(words, stdin_texts, depth):
    if not words:
        return
    name = os.path.basename(words[0])
    args = words[1:]
    if name in ("sudo", "doas"):
        raise BlockedError(f"{name} is not allowed")
    if name == "git":
        index = 0
        while index < len(args) and args[index].startswith("-"):
            index += 2 if args[index] in GIT_OPTIONS_WITH_ARGUMENT else 1
        if index < len(args) and args[index] == "push":
            raise BlockedError("git push is left to the user")
    elif name == "rm":
        recursive = force = False
        for arg in args:
            if arg == "--":
                break
            if arg in ("--recursive",):
                recursive = True
            elif arg == "--force":
                force = True
            elif arg.startswith("-") and not arg.startswith("--"):
                recursive = recursive or bool(set(arg) & {"r", "R"})
                force = force or "f" in arg
        if recursive and force:
            raise BlockedError(
                "rm with both recursive and force options is not allowed;"
                " use `command rm -r` without -f instead"
            )
    elif name == "find":
        for index, arg in enumerate(args):
            if arg in FIND_ACTIONS:
                action = []
                for word in args[index + 1 :]:
                    if word in (";", "+"):
                        break
                    action.append(word)
                check_words(strip_wrappers(action), [], depth)
    elif name == "eval":
        check_text(" ".join(args), depth + 1)
    elif name in SHELLS:
        operands = skip_options(args, {"-o", "+o", "-O", "+O"})
        if any(
            arg.startswith("-") and not arg.startswith("--") and "c" in arg
            for arg in args[: len(args) - len(operands)]
        ):
            if operands:
                check_text(operands[0], depth + 1)
        elif not operands:
            for stdin_text in stdin_texts:
                check_text(stdin_text, depth + 1)


def main():
    try:
        event = json.load(sys.stdin)
        command = event["tool_input"]["command"]
        if not isinstance(command, str):
            raise BlockedError("the command is not a string")
        check_text(command)
    except BlockedError as error:
        print(f"bash-guard: {error}", file=sys.stderr)
        return 2
    except Exception as error:  # Fail closed: a doubtful command must not run.
        print(f"bash-guard: cannot check the command: {error!r}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
