from convo_parser import DialogState, lines_to_state


multiline_test = """
? thought
Sophie:: Line A
Sophie:: Line B
	Eucl:: Response A
Sophie:: Line C
	Eucl:: Response B
"""


def test_multiline_speech():
    assert lines_to_state(multiline_test.split("\n")) == DialogState(
        states=[
            DialogState(
                states=[],
                directions=[],
                side_effects=[],
                choices=[["Response A"]],
                speaker="Eucl",
                new_choice=False,
            ),
            DialogState(
                states=[],
                directions=[],
                side_effects=[],
                choices=[["Response B"]],
                speaker="Eucl",
                new_choice=False,
            ),
        ],
        directions=["thought"],
        side_effects=[],
        choices=[["Line A", "Line B"], ["Line C"]],
        speaker="Sophie",
        new_choice=True,
    )
