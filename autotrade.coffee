class Autotrade

    constructor: (@say, @msg, @use_activity=true, @timeout=300) ->

    timer: () =>

        if @running

            if @current_time == @timeout

                if (not @use_activity) or (@use_activity and @activity)

                    @current_time = 0
                    @activity = false
                    @say(@msg)

            else

                @current_time += 1

            setInterval(@timer, 1000)


    activity: () ->

        @activity = true


    start: () ->

        @current_time = 0
        @running = true
        @activity = false
        setInterval(@timer, 1000)


    stop: () ->

        @running = false
