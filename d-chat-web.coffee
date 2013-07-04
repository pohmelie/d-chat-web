#= require <ui.coffee>
#= require <bnet.coffee>


class Dchat

    constructor: (@tabs_id, @chat_id, @input_id, @commands_prefix="\\") ->

        @tabs = new ui.Tabs(@tabs_id, @chat_id, @input_id)
        @bn = new bnet.Bnet("rubattle.net", 6112, socket_connect, socket_send, @login_error, @chat_event)
        $(@input_id).on("keydown", @input_key)
        $(window).on("keydown", @global_key)

        @nicknames = {}
        @users_count = 0


    say: (phrases...) ->

        html = "<div>"
        for phrase in phrases

            if typeof(phrase) isnt "object"
                phrase = ["color-default", phrase]

            [color, msg] = phrase
            html += "<span class='#{color}'>#{msg}</span>"

        html += "</div>"
        @tabs.echo(html)


    login_error: (stage, reason="unknown") =>


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

                @nicknames[pack.username] = nickname
                @users_count += 1

            when "ID_LEAVE"

                @nicknames[pack.username] = null
                @users_count -= 1

            when "ID_INFO"

                @say(["color-time", @time()], ["color-system", pack.text])

            when "ID_ERROR"

                @say(["color-time", @time()], ["color-error", pack.text])

            when "ID_TALK", "ID_EMOTE"

                @say(
                    ["color-time", @time()],
                    ["color-nickname", @nicknames[pack.username]],
                    ["color-delimiter", "*"],
                    ["color-nickname", pack.username],
                    ["color-delimiter", ": "],
                    ["color-text", pack.text]
                )

            when "ID_CHANNEL"

                @channel = pack.text


    global_key: (e) =>

        switch e.which

            when 39  # right

                if e.ctrlKey

                    @tabs.next()
                    e.preventDefault()

            when 37  # left

                if e.ctrlKey

                    @tabs.prev()
                    e.preventDefault()

            when 87  # 'w'

                if e.ctrlKey

                    @tabs.remove()
                    e.preventDefault()


            when 83  # 's'

                if e.ctrlKey

                    null
                    e.preventDefault()


            else

                console.log(e.currentTarget, e.which, e.ctrlKey, e.altKey, e.shiftKey)


    input_key: (e) =>

        switch e.which

            when 13  # enter

                @bn.login("pohmelie9", "chat")
                return

                msg = @tabs.active.prefix + $(@input_id).val().trim()
                $(@input_id).val("")

                if msg[0] is @commands_prefix

                    @command(msg.substring(1))

                else

                    @bn.say(msg)

            when 9  # tab

                # autocomplete
                e.preventDefault()


    command: (cmd) ->

        ###
            connect
            disconnect
            echo
            reload
            autoscroll
            color-*
            commands-prefix blah
            tab-mode on/off
            help
        ###

        cmd = cmd.split(" ")

        switch cmd[0]

            when "toggle-autoscroll"

                console.log("autoscroll")


$(() ->
    dchat = new Dchat("#tabs", "#chat", "#input")
    window.on_socket_get = dchat.bn.on_packet

    $("#button").on("mousedown", socket_disconnect)
)
