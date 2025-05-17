from __future__ import annotations

import os
from pathlib import Path
import re
from dataclasses import dataclass
import subprocess


"""
Script to convert conversations in ../convos to a gdscript file that becomes
the tres file

The flow is .convos -> Python models -> gdscript models -> tres file

Alternatively we could generate the tres directly - but doing the intermediate
steps makes things easier to debug, and doesn't add too much complexity

Run with python dialog/tools/convo_parser.py


Notes:
pprint.pprint(asdict(tree))
"""


class CodeBuilder:
    indentation = 0
    code = ""

    def add_line(self, str):
        self.code += "\t" * self.indentation + str + "\n"

    def indent(self):
        self.indentation += 1

    def dedent(self):
        self.indentation -= 1


@dataclass
class Direction:
    text: str


@dataclass
class Speech:
    speaker: str
    text: str


@dataclass
class Command:
    command: str


LineData = Direction | Speech | Command


@dataclass
class DialogState:
    """
    _short_choices: Array[String] = [],
    _choices: Array[String] = [],
    _side_effects: Array[Variant] = [],
    _states: Array[DialogState] = [],
    _directions: Array[String] = [],
    _speaker: String,
    """

    states: list[DialogState]
    directions: list[str]
    side_effects: list[str]
    choices: list[list[str]]
    speaker: str = ""
    new_choice: bool = True

    def add(self, item: LineData | None):
        if item is None:
            return
        if isinstance(item, Direction):
            self.directions.append(item.text)
        elif isinstance(item, Command):
            self.side_effects.append(item.command)
        elif isinstance(item, Speech):
            if self.speaker and item.speaker != self.speaker:
                raise Exception(
                    f"Invalid speaker found {item.speaker}, expected {self.speaker}."
                )
            self.speaker = item.speaker
            if self.new_choice:
                self.new_choice = False
                self.choices.append([item.text])
            else:
                self.choices[-1].append(item.text)
        else:
            raise Exception(item)


def indentation(str) -> int:
    count = 0
    while str.startswith("\t"):
        count += 1
        str = str[1:]  # Remove the prefix from the beginning
    return count


COMMAND_REGEX = re.compile(r"\s*~([^~\n]+)~")
# 0: constant.other.symbol
# 1: markup.italic

SPEECH_REGEX = re.compile(r"^(\s*)(.+?)(::)(.*)")
"""
1: text.whitespace
2: variable.parameter
3: punctuation.separator.key-value
4: text.whitespace
"""

DIRECTION_REGEX = r"^(\s*)(\?)(.*)"
"""
1: text.whitespace
2: markup.italic
3: string.other
"""
"""
    # Catch-all: italicize any leftover text
    - match: '.+'
      scope: markup.italic

"""


def parse_line(line: str) -> LineData | None:
    stripped = line.strip()
    if stripped == "" or stripped.startswith("#"):
        # Ignore blank lines and comments
        return None
    elif stripped.startswith("?"):
        return Direction(text=stripped[1:].strip())
    elif SPEECH_REGEX.match(line):
        m = SPEECH_REGEX.match(line)
        return Speech(speaker=m.group(2), text=m.group(4).strip())
    elif COMMAND_REGEX.match(line):
        m = COMMAND_REGEX.match(line)
        return Command(command=m.group(1))
    else:
        print("Unknown")
        print(stripped)
        return None


def lines_to_state(lines: list[str], level: int = 0) -> DialogState:
    ds = DialogState([], [], [], [], "", True)
    while lines:
        line = lines[0]
        indent = indentation(line)
        parsed = parse_line(line)
        if parsed is None:
            lines.pop(0)
            continue
        if indent == level:
            lines.pop(0)
            try:
                ds.add(parsed)
            except Exception as e:
                raise Exception(
                    f"Error adding line {line}, with indentation {indent}."
                ) from e
        elif indent > level:
            ds.new_choice = True
            ds.states.append(lines_to_state(lines, level + 1))
        elif indent < level:
            return ds
        else:
            raise Exception(level, indent)

    return ds


def write_tree(tree: DialogState, cb: CodeBuilder, skip_object: bool = False):
    if not skip_object:
        cb.add_line("DialogState.create(")
    cb.indent()
    cb.add_line(f"{repr(tree.speaker)},")
    cb.add_line(f"{repr(tree.directions)},")
    cb.add_line(f"{repr([choice[0] for choice in tree.choices])},")
    cb.add_line(f"{repr(['\n'.join(choice) for choice in tree.choices])},")
    cb.add_line("[")
    cb.indent()
    for state in tree.states:
        write_tree(state, cb)
    if not tree.states:
        cb.add_line("null")
    cb.dedent()
    cb.add_line("],")
    cb.add_line(f"{repr(tree.side_effects)},")
    cb.dedent()
    if not skip_object:
        cb.add_line("),")


def write_root(name: str, tree: DialogState, cb: CodeBuilder):
    cb.add_line(f'trees["{name}"] = DialogState.create(')
    write_tree(tree, cb, skip_object=True)
    cb.add_line(")")


cb = CodeBuilder()

cb.add_line("""extends MainLoop

# DO NOT EDIT THIS FILE DIRECTLY
# Generated via convo_parser.py, and used to generate tres file.

# .zshrc has alias /Applications/Godot4.4.app/Contents/MacOS/Godot
# Run with godot4 --headless --script res://dialog/tools/SCRIPT.gd
func _initialize():
	print("Generating dialogs...")
	var res = build()
	ResourceSaver.save(res, "res://dialog/SCRIPT.tres")
	print("Saved dialog.tres")

func _process(_delta):
	return true

func build():""")

cb.indent()
cb.add_line("var collection = DialogTreeCollection.new()")
cb.add_line("var trees: Dictionary[String, DialogState] = {}")


dialog_root = Path(__file__).resolve().parent.parent

for conversation in os.listdir(os.path.join(dialog_root, "convos")):
    if not conversation.endswith(".convo"):
        continue
    with open(os.path.join(dialog_root, "convos", conversation)) as infile:
        lines = infile.readlines()

    try:
        tree = lines_to_state(lines)
    except Exception as e:
        raise Exception(f"Error parsing conversation {conversation}") from e
    write_root(conversation.split(".")[0], tree, cb)

cb.add_line("collection.trees = trees")
cb.add_line("return collection")

with open(os.path.join(Path(__file__).resolve().parent, "SCRIPT.gd"), "w") as outfile:
    outfile.writelines(cb.code)


subprocess.run(
    [
        "/Applications/Godot4.4.app/Contents/MacOS/Godot",
        "--headless",
        "--script",
        # "--verbose",
        "res://dialog/tools/SCRIPT.gd",
    ]
)
