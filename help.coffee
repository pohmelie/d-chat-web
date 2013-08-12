help_message = """
d-chat-web help information.
Commands:

    \\echo message
        Print message to screen without sending to battle.net.

    \\connect account password
        Disconnect if connected and connect to battle.net.

    \\disconnect
        Disconnect from battle.net.

    \\reload
        Reloads 'init' file. 'init' file loads on start and simply executes like user input.

    \\autoscroll
        Switch autoscroll on/off. Default 'on'.

    \\help
        Show help information.

    \\tab-mode
        Switch tab-mode on/off. Default 'on'.

    \\autotrade-message message
        Set autotrade message.

    \\autotrade-timeout timeout
        Set autotrade timeout in seconds.

    \\autotrade-activity
        Switch autotrade use-activity value. When use-activity mode is on, autotrade message won't appear before anyone will say something. This is good for 'not to spam' and 'be quiet'.

    \\autotrade-start
        Start autotrade loop.

    \\autotrade-stop
        Stop autotrade loop.


Shortcuts:

    ctrl + right/left
        Switch to next/previous tab.

    ctrl + w
        Close current tab.

    ctrl + s
        Switch autotrade on/off.

    ctrl + r
        Same as '\\reload'.

    ctrl + d
        Same as '\\disconnect'.

    ctrl + m
        Switch to main tab.

    up/down
        Browse commands history.

    tab
        Request autocomplete. Autocompletes if there is one possibility, prints all possibilities else.
"""
