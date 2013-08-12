class Autotrade

    constructor: (@say, @msg="N enigma free PLZ PLZ!!", @use_activity=true, @timeout=300) ->

    timer: () =>

        if @running

            if @msg == ""

                @stop()
                return

            if @current_time == @timeout - 1

                if (not @use_activity) or (@use_activity and @activity)

                    @current_time = 0
                    @activity = false
                    @say(@msg)

            else

                @current_time += 1

            setTimeout(@timer, 1000)


    trigger_activity: () ->

        @activity = true


    start: () ->

        @current_time = 0
        @running = true
        @activity = false
        setTimeout(@timer, 1000)


    stop: () ->

        @running = false
