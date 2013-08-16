#= require <ui.coffee>
#= require <bnet.coffee>
#= require <java-socket-bridge.coffee>
#= require <history.coffee>
#= require <autocomplete.coffee>
#= require <intro.coffee>
#= require <autotrade.coffee>
#= require <calc.coffee>


class Dchat

    constructor: (@tabs_id, @chat_id, @user_list_id, @input_id, @commands_prefix="\\") ->

        @max_symbols = 199

        @nicknames = {}
        @users_count = 0
        @channel = null
        @connected = false
        @autoscroll = localStorage.autoscroll or true
        @account = localStorage.account

        if localStorage.hashed_password?

            @hashed_password = JSON.parse(localStorage.hashed_password)

        @tab_mode = localStorage.tab_mode or true

        @replacing_symbols = {
            ">":"&gt;",
            "<":"&lt;",
            " ":"&nbsp;<wbr>",
            "\n":"<br>",
        }

        @commands_list = [
            "echo",
            "connect",
            "disconnect",
            "reload",
            "autoscroll",
            "help",
            "tab-mode",
            "autotrade-message",
            "autotrade-timeout",
            "autotrade-activity",
            "autotrade-start",
            "autotrade-stop",
            "autotrade-info",
            "calc"
        ]
        @autocomplete = new Autocomplete(@commands_list.map((c) => @commands_prefix + c))
        @autotrade = new Autotrade(
            @common_message,
            localStorage.autotrade_msg or "N enigma free PLZ PLZ!!",
            localStorage.autotrade_use_activity or true,
            localStorage.autotrade_timeout or 300
        )

        @history = new History()
        @tabs = new ui.Tabs(@tabs_id, @chat_id, @user_list_id, @input_id, @render_phrases, @refresh_title)
        @tabs.set_active(@tabs.main)
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

        @refresh_title()
        @show_intro()

        if @account? and @hashed_password?

            @command("connect")

        if localStorage.autotrade is true

            @command("autotrade-start")


    render_phrases: (phrases...) =>

        html = ""
        for phrase in phrases

            if typeof(phrase) isnt "object"
                phrase = ["color-text", phrase]

            [color, msg, raw] = phrase

            if raw isnt true
                msg = @prepare_string(msg)

            html += "<span class='#{color}'>#{msg}</span>"

        return html


    echo: (phrases...) ->

        @tabs.echo(
            "<div>#{@render_phrases([['color-time', @time()]].concat(phrases)...)}</div>",
            @autoscroll
        )


    whisper: (username, phrases...) ->

        @tabs.whisper(
            username,
            "<div>#{@render_phrases([['color-time', @time()]].concat(phrases)...)}</div>",
            @autoscroll
        )


    login_error: (stage, reason) =>

        reasons = ["Account doesn't exists", "Wrong password"]

        if reasons[reason - 1]?
            @echo(["color-error", "Login failed. #{reasons[reason - 1]}."])
        else
            @echo(["color-error", "Login failed. (stage = #{stage}, reason = #{reason})."])

        @disconnect()


    socket_error: (msg) =>

        @echo(["color-error", "Java applet error: #{msg}"])
        @disconnect()
        return


    connect: (acc, pass, hashed=false) =>

        @disconnect()

        if java_socket_bridge_ready_flag

            @command("echo Connecting...")
            @bn.login(acc, pass, hashed)
            @connected = true

        else

            setTimeout((() => @connect(acc, pass, hashed)), 100)


    disconnect: () ->

        if @connected
            java_socket_bridge_disconnect()
            @connected = false
            @command("echo Disconnected.")
            @users_count = 0
            @channel = null
            @refresh_title()
            @tabs.user_list.clear()

            for k, v of @nicknames

                @autocomplete.remove("*#{k}")

            @nicknames = {}


    refresh_title: () =>

        if @connected

            total_unread = @tabs.tabs.reduce(((u, t) -> u + t.unread), 0)

            if total_unread != 0

                title = "[#{total_unread}] #{@channel} (#{@users_count})"

            else

                title = "#{@channel} (#{@users_count})"

        else

            title = "d-chat-web"

        @tabs.main.set_title(title)
        $(document).attr("title", title)


    time: () ->

        d = new Date()
        s = [d.getHours(), d.getMinutes(), d.getSeconds()].map((x) ->
            if x < 10
                return "0" + x.toString()
            else
                return x.toString()
        ).join(":")

        return "[#{s}] "


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
                @autocomplete.add("*#{pack.username}")
                @tabs.user_list.add(pack.username, nickname)
                @refresh_title()

            when "ID_LEAVE"

                delete @nicknames[pack.username]
                @autocomplete.remove("*#{pack.username}")
                @tabs.user_list.remove(pack.username)
                @users_count -= 1
                @refresh_title()

            when "ID_INFO"

                @echo(["color-system", pack.text])

            when "ID_ERROR"

                @echo(["color-error", pack.text])

            when "ID_TALK", "ID_EMOTE"

                @echo(
                    ["color-nickname", @nicknames[pack.username]],
                    ["color-delimiter", "*"],
                    ["color-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-text", pack.text]
                )
                @autotrade.trigger_activity()

            when "ID_CHANNEL"

                @channel = pack.text
                @users_count = 0

                for k, v of @nicknames

                    @autocomplete.remove("*#{k}")

                @nicknames = {}
                @tabs.user_list.clear()
                @refresh_title()

            when "ID_WHISPER"

                if @tab_mode

                    @whisper(
                        "*#{pack.username}",
                        ["color-nickname", (@nicknames[pack.username] or "")],
                        ["color-delimiter", "*"],
                        ["color-nickname", pack.username],
                        ["color-delimiter", ": "],
                        ["color-text", pack.text]
                    )

                else

                    @echo(
                        ["color-whisper-nickname", (@nicknames[pack.username] or "") + "*#{pack.username}"],
                        ["color-delimiter", " -> "],
                        ["color-whisper-nickname", "*#{@account}"],
                        ["color-delimiter", ": "],
                        ["color-whisper", pack.text]
                    )

            when "ID_WHISPERSENT"

                if @tab_mode

                    @whisper(
                        "*#{pack.username}",
                        ["color-delimiter", "*"],
                        ["color-nickname", @account],
                        ["color-delimiter", ": "],
                        ["color-text", pack.text]
                    )
                    @tabs.set_active(@tabs.get_tab("*#{pack.username}"))

                else

                    @echo(
                        ["color-whisper-nickname", "*#{@account}"],
                        ["color-delimiter", " -> "],
                        ["color-whisper-nickname", (@nicknames[pack.username] or "") + "*#{pack.username}"],
                        ["color-delimiter", ": "],
                        ["color-whisper", pack.text]
                    )

            when "ID_BROADCAST"

                @echo(
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

                    @toggle_autotrade()
                    e.preventDefault()

                when 82  # 'r'

                    @load_init_file()
                    e.preventDefault()

                when 68  # 'd'

                    @disconnect()
                    e.preventDefault()

                when 77  # 'm'

                    @tabs.set_active()
                    e.preventDefault()

                when 73  # 'i'

                    @command("autotrade-info")
                    e.preventDefault()

        else if e.which == 112

            @show_help()
            e.preventDefault()


        console.log(e.currentTarget, e.which, e.ctrlKey, e.altKey, e.shiftKey)


    toggle_autotrade: () ->

        if @autotrade.running

            @command("autotrade-stop")

        else

            @command("autotrade-start")


    toggle_autoscroll: () ->

        @autoscroll = not @autoscroll
        @command("echo Autoscroll set to #{@autoscroll}.")


    common_message: (msg) =>

        if msg isnt ""

            if msg[0] is @commands_prefix

                @command(msg.substring(1))

            else if @connected and @channel?

                smsg = msg
                while smsg != ""

                    @bn.say(smsg.substr(0, @max_symbols))
                    smsg = smsg.substr(@max_symbols)

                if msg[0] isnt "/"

                    @echo(
                        ["color-delimiter", "*"],
                        ["color-nickname", @account],
                        ["color-delimiter", ": "],
                        ["color-text", msg]
                    )


    input_key: (e) =>

        switch e.which

            when 13  # enter

                @history.add($(@input_id).val())
                @history.reset()

                msg = @tabs.active.prefix + $(@input_id).val().trim()
                $(@input_id).val("")
                @common_message(msg)

            when 9  # tab

                msg = $(@input_id).val()
                words = @autocomplete.filter(msg)
                if words.length == 1

                    $(@input_id).val(msg + @autocomplete.cut(msg, words[0]))

                else if words.length > 1

                    common = @autocomplete.cut(msg, @autocomplete.common(words))
                    $(@input_id).val(msg + common)

                    if common.length == 0

                        words.unshift("#{words.length} possibilities:")
                        @echo(["color-autocomplete", words.join("\n")])

                e.preventDefault()

            when 38  # up

                if @history.length() > 0

                    $(@input_id).val(@history.up())

                e.preventDefault()

            when 40  # down

                if @history.length() > 0

                    $(@input_id).val(@history.down())

                e.preventDefault()


    command: (cmd) ->

        cmd = cmd.split(" ")

        switch cmd[0].toLowerCase()

            when "echo"

                if cmd.length > 1

                    @echo(["color-echo", cmd[1..-1].join(" ")])

            when "connect"

                [acc, pass] = cmd[1..-1].filter((x) -> x isnt "")

                if acc? and pass?

                    localStorage.account = @account = acc
                    @connect(acc, pass)
                    localStorage.hashed_password = JSON.stringify(@bn.hashpass)

                else if localStorage.account? and localStorage.hashed_password?

                    @account = localStorage.account
                    @connect(localStorage.account, JSON.parse(localStorage.hashed_password), true)

                else

                    @command("echo Can't connect without account name and password. Type '#{@commands_prefix}help' for more information.")

            when "disconnect"

                @disconnect()

            when "reload"

                @load_init_file()

            when "autoscroll"

                @toggle_autoscroll()

            when "help"

                @show_help()

            when "tab-mode"

                @toggle_tab_mode()

            when "autotrade-message"

                if cmd.length > 1

                    localStorage.autotrade_msg = @autotrade.msg = cmd[1..-1].join(" ")

                @command("echo Current autotrade message is '#{@autotrade.msg}'.")

            when "autotrade-timeout"

                if cmd.length > 1

                    t = parseInt(cmd[1])

                    if isNaN(t) or t <= 0

                        @command("echo Bad number '#{cmd[1]}'.")

                    else

                        localStorage.autotrade_timeout = @autotrade.timeout = t

                @command("echo Current autotrade timeout is '#{@autotrade.timeout}'.")

            when "autotrade-activity"

                localStorage.autotrade_use_activity = @autotrade.use_activity = not @autotrade.use_activity
                @command("echo Autotrade use-activity set to '#{@autotrade.use_activity}'.")

            when "autotrade-start"

                @command("echo Autotrade started with message = '#{@autotrade.msg}' and timeout = '#{@autotrade.timeout}'.")
                @autotrade.start()
                localStorage.autotrade = true

            when "autotrade-stop"

                @command("echo Autotrade stopped.")
                @autotrade.stop()
                localStorage.autotrade = false

            when "autotrade-info"

                @command("""
                echo Autotrade info:
                running = #{@autotrade.running}
                message = #{@autotrade.msg}
                time = #{@autotrade.current_time}/#{@autotrade.timeout}
                use activity = #{@autotrade.use_activity}
                activity = #{@autotrade.activity}
                """)

            when "calc"

                @command("echo #{Calculator.calc(cmd[1..-1])}")

            else

                @command("echo Unknown command '#{cmd[0].toLowerCase()}'.")


    toggle_tab_mode: () ->

        @tab_mode = not @tab_mode
        @command("echo Tab mode set to #{@tab_mode}.")

        if not @tab_mode

            @tabs.tabs.filter((t) -> t.closeable).forEach(@tabs.remove)
            @refresh_title()


    load_init_file: (data) =>

        if data?

            data.split("\n").map((x) -> x.trim()).forEach(@common_message)

        else
            $.get("init", @load_init_file, "text").error(() =>
                @command("echo Initialization file 'init' missing.")
            )


    show_help: () ->

        @command("echo #{help_message}")


    prepare_string: (str) ->

        for find, replace of @replacing_symbols
            str = str.replace(new RegExp(find, 'g'), replace)

        return str


    show_intro: () ->

        @echo(["color-text", intro, true])


$(() ->
    dchat = new Dchat("#tabs", "#chat", "#user-list", "#input")
    window.java_socket_bridge_on_receive = dchat.bn.on_packet
    window.java_socket_bridge_error = dchat.socket_error
    $(window).unload(java_socket_bridge_disconnect)
)
