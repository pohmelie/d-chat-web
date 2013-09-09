class Autotrade

    constructor: (@say, @msg="N enigma free PLZ PLZ!!", @use_activity=10, @timeout=300) ->

        @running = false
        @current_time = 0
        @activity = 0


    timer: () =>

        if @running

            if @msg == ""

                @stop()
                return

            if @current_time == @timeout - 1

                if @activity >= @use_activity

                    @current_time = 0
                    @activity = 0
                    @say(@msg)

            else

                @current_time += 1

            setTimeout(@timer, 1000)


    trigger_activity: () ->

        @activity += 1


    start: () ->

        @current_time = 0
        @running = true
        @activity = 0
        setTimeout(@timer, 1000)


    stop: () ->

        @running = false
