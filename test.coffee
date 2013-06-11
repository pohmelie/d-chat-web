@on_socket_get = (msg, count) ->
    console.log("got something")
    console.log(msg, count)
    for num in [0..count - 1]
        console.log(msg[num])

@run = ->
    console.log("run pressed")
    console.log(socket_connect("rubattle.net", 6112))
    socket_send([1])
