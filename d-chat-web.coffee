#= require <ui.coffee>
#= require <bnet.coffee>
#= require <java-socket-bridge.coffee>


class Dchat

    constructor: (@tabs_id, @chat_id, @input_id, @commands_prefix="\\") ->

        @nicknames = {}
        @users_count = 0
        @channel = null
        @connected = false
        @autoscroll = true
        @account = null

        @tabs = new ui.Tabs(@tabs_id, @chat_id, @input_id)
        @bn = new bnet.Bnet(
            "rubattle.net",
            6112,
            java_socket_bridge_connect,
            java_socket_bridge_send,
            @login_error,
            @chat_event
        )
        $(@input_id).on("keydown", @input_key)
        $(window).on("keydown", @global_key)

        @refresh_main_tab_title()
        @load_init_file()


    say: (phrases...) ->

        html = "<div>"
        for phrase in [["color-time", @time()]].concat(phrases)

            if typeof(phrase) isnt "object"
                phrase = ["color-text", phrase]

            [color, msg] = phrase
            html += "<span class='#{color}'>#{msg}</span>"

        html += "</div>"
        @tabs.echo(html, @autoscroll)


    login_error: (stage, reason) =>

        reasons = ["Account doesn't exists", "Wrong password"]

        if reasons[reason - 1]?
            @say(["color-error", "Login failed. #{reasons[reason - 1]}."])
        else
            @say(["color-error", "Login failed. (stage = #{stage}, reason = #{reason})."])

        @disconnect()


    socket_error: (msg) =>

        @say(["color-error", "Java applet error: " + msg])
        @disconnect()
        return


    connect: (acc, pass) =>

        @disconnect()

        if java_socket_bridge_ready_flag

            @command("echo Connecting...")
            @bn.login(acc, pass)
            @connected = true

        else

            setTimeout((() => @connect(acc, pass)), 100)


    disconnect: () ->

        if @connected
            java_socket_bridge_disconnect()
            @connected = false
            @command("echo Disconnected.")
            @users_count = 0
            @channel = null
            @refresh_main_tab_title()


    refresh_main_tab_title: () ->

        if @connected
            @tabs.main.set_title("#{@channel} (#{@users_count})")
        else
            @tabs.main.set_title("d-chat-web")


    time: () ->

        d = new Date()
        s = [d.getHours(), d.getMinutes(), d.getSeconds()].map((x) ->
            if x < 10
                return "0" + x.toString()
            else
                return x.toString()
        ).join(":")

        return "[" + s + "] "


    chat_event: (pack) =>

        switch pack.event_id

            when "ID_USER", "ID_JOIN", "ID_USERFLAGS"

                nickname = ""
                if pack.text.substring(0, 4) is "PX2D"
                    s = pack.text.split(",")
                    if s.length > 1
                        nickname = s[1]

                if not @nicknames[pack.username]?
                    @users_count += 1

                @nicknames[pack.username] = nickname
                @refresh_main_tab_title()

            when "ID_LEAVE"

                @nicknames[pack.username] = null
                @users_count -= 1
                @refresh_main_tab_title()

            when "ID_INFO"

                @say(["color-system", pack.text])

            when "ID_ERROR"

                @say(["color-error", pack.text])

            when "ID_TALK", "ID_EMOTE"

                @say(
                    ["color-nickname", @nicknames[pack.username]],
                    ["color-delimiter", "*"],
                    ["color-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-text", pack.text]
                )

            when "ID_CHANNEL"

                @channel = pack.text
                @users_count = 0
                @nicknames = {}
                @refresh_main_tab_title()

            when "ID_WHISPER"

                @say(
                    ["color-whisper-nickname", @nicknames[pack.username] or ""],
                    ["color-delimiter", "*"],
                    ["color-whisper-nickname", pack.username],
                    ["color-delimiter", " -> "],
                    ["color-whisper-nickname", "*" + @account],
                    ["color-delimiter", ": "],
                    ["color-whisper", pack.text]
                )

            when "ID_WHISPERSENT"

                @say(
                    ["color-whisper-nickname", "*" + @account],
                    ["color-delimiter", " -> "],
                    ["color-whisper-nickname", @nicknames[pack.username] or ""],
                    ["color-delimiter", "*"],
                    ["color-whisper-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-whisper", pack.text]
                )

            when "ID_BROADCAST"

                @say(
                    ["color-whisper-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-whisper", pack.text]
                )



    global_key: (e) =>

        if e.ctrlKey

            switch e.which

                when 39  # right

                    @tabs.next()
                    e.preventDefault()

                when 37  # left

                    @tabs.prev()
                    e.preventDefault()

                when 87  # 'w'

                    @tabs.remove()
                    e.preventDefault()

                when 83  # 's'

                    @toggle_autoscroll()
                    e.preventDefault()

                when 82  # 'r'

                    @load_init_file()
                    e.preventDefault()

                when 68  # 'd'

                    @disconnect()
                    e.preventDefault()

        console.log(e.currentTarget, e.which, e.ctrlKey, e.altKey, e.shiftKey)


    toggle_autoscroll: () ->

        @autoscroll = not @autoscroll
        @command("echo Autoscroll set to #{@autoscroll}.")


    common_message: (msg) =>

        if msg isnt ""

            if msg[0] is @commands_prefix

                @command(msg.substring(1))

            else if @connected and @channel?

                @bn.say(msg)

                if msg[0] isnt "/"

                    @say(
                        ["color-delimiter", "*"],
                        ["color-nickname", @account],
                        ["color-delimiter", ": "],
                        ["color-text", msg]
                    )


    input_key: (e) =>

        switch e.which

            when 13  # enter

                msg = @tabs.active.prefix + $(@input_id).val().trim()
                $(@input_id).val("")
                @common_message(msg)

            when 9  # tab

                # autocomplete
                e.preventDefault()


    autocomplete: () ->

        msg = @tabs.active.prefix + $(@input_id).val().trim()
        # $(@input_id).val("")



    command: (cmd) ->

        ###
            commands history
            color-*
            tab-mode on/off
            autocomplete
            help
        ###

        cmd = cmd.split(" ")

        switch cmd[0].toLowerCase()

            when "echo"

                if cmd.length > 1

                    @say(["color-echo", cmd[1..-1].join(" ")])

            when "connect"

                [acc, pass] = cmd[1..-1].filter((x) -> x isnt "")

                if acc? and pass?

                    @account = acc
                    @connect(acc, pass)

                else

                    @command("echo Can't connect without account name and password. Type '#{@commands_prefix}help' for more information.")

            when "disconnect"

                @disconnect()

            when "reload"

                @load_init_file()

            when "autoscroll"

                @toggle_autoscroll()

            when "commands-prefix"

                m = cmd[1..-1].join(" ")

                if m isnt ""

                    @commands_prefix = m[0]

            else

                @command("echo Unknown command '#{cmd[0].toLowerCase()}'.")


    load_init_file: (data) =>

        if data?

            data.split("\n").map((x) -> x.trim()).forEach(@common_message)

        else
            $.get("init", @load_init_file, "text").error(() =>
                @command("echo Initialization file 'init' missing.")
            )


$(() ->
    dchat = new Dchat("#tabs", "#chat", "#input")
    window.java_socket_bridge_on_receive = dchat.bn.on_packet
    window.java_socket_bridge_error = dchat.socket_error
    $(window).unload(java_socket_bridge_disconnect)
)
