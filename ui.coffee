#= require <stylist.coffee>


class ui

    class @Tab

        constructor: (@title, @prefix, @account, @id, @closeable=true) ->

            @html = []
            @input = ""


        add: (html) ->

            @html.push(html)


        set_title: (@title) ->

            $(@id).html(@title)


    class @Tabs

        constructor: (@tabs_id, @chat_id, @user_list_id, @input_id, @render_phrases) ->

            @tabs_float_index = 0
            @stylist = new Stylist()
            @user_list = new ui.UserList(@user_list_id, @render_phrases)

            @tabs = []
            @add("", "", false)

            @main = @active = @tabs[0]

            line_height = $(@main.id).outerHeight(true)
            @stylist.css[@tabs_id] = {
                "line-height":"#{line_height + 2}px"
            }

            @stylist.update()
            @set_active(@main)
            @autosize()


        whisper: (username, html, scroll_down=true) ->


        echo: (html, scroll_down=true) ->

            @main.add(html)
            if @main is @active
                $(@chat_id).append(html)

                if(scroll_down)
                    $(@chat_id).scrollTop($(@chat_id)[0].scrollHeight)


        add: (title="", prefix="", account="", closeable=true) ->

            while $("#tab" + @tabs_float_index.toString()).length != 0
                @tabs_float_index += 1

            id = "tab" + @tabs_float_index.toString()
            tab = new ui.Tab(title, prefix, account, "#" + id, closeable)
            @tabs.push(tab)

            $(@tabs_id).append("<span id=#{id}></span> ")
            $("#" + id).addClass("tab border color-border color-text").html(title)

            $("#" + id).on(
                "mousedown",
                (e) =>
                    switch e.which

                        when 1
                            @set_active(tab)

                        when 2
                            @remove(tab)

                    e.preventDefault()
            )

            @autosize()


        set_active: (tab) ->

            $(@active.id).removeClass("color-active-tab-back color-active-tab-fore")
            $(tab.id).addClass("color-active-tab-back color-active-tab-fore")

            @active.input = $(@input_id).val()
            @active = tab
            $(@input_id).val(@active.input)

            $(@chat_id).html(@active.html.join(""))
            $(@chat_id).scrollTop($(@chat_id)[0].scrollHeight)

            $(@input_id).focus()


        remove: (tab=@active) ->

            if tab.closeable == true

                if @active is tab

                    @set_active(@main)

                @tabs = @tabs.filter((t) -> t isnt tab)
                $(tab.id).remove()

                @autosize()


        autosize: () =>

            height = (
                $(@tabs_id).outerHeight(true) +
                $(@chat_id).outerHeight(true) +
                $(@input_id).outerHeight(true) -
                $(@chat_id).innerHeight() +
                10  # padding
            )

            for id in [@chat_id, @user_list_id]
                @stylist.css[id] = {
                    "height":"calc(100% - #{height}px)"
                }

            @stylist.update()


        index: (tab=@active) ->

            for i in [0...@tabs.length]

                if tab is @tabs[i]

                    return i


        next: () ->

            if @tabs.length > 1

                @set_active(@tabs[(@index() + 1) % @tabs.length])


        prev: () ->

            if @tabs.length > 1

                @set_active(@tabs[(@tabs.length + @index() - 1) % @tabs.length])


    class @UserList

        constructor: (@user_list_id, @render_phrases) ->

            @clear()


        add: (username, nickname) ->

            msgs = [
                ["color-delimiter", "*"],
                ["color-user-list-account", username]
            ]

            if nickname != ""

                msgs.push(
                    ["color-user-list-nickname", " (#{nickname})"]
                )

            msg = @render_phrases(msgs...)

            if @mem[username]?

                $("#{@user_list_id}-member-#{@mem[username]}").html(msg)

            else

                @mem[username] = @internal_id
                $(@user_list_id).append("""
                    <div
                            id='#{@user_list_id.substr(1)}-member-#{@mem[username]}'
                            class='user-list-member'>
                        #{msg}
                    </div>
                """)
                @internal_id = @internal_id + 1


        remove: (username) ->

            if @mem[username]?

                $("#{@user_list_id}-member-#{@mem[username]}").remove()
                delete @mem[username]


        clear: () ->

            $(@user_list_id).html("")
            @internal_id = 0
            @mem = {}
