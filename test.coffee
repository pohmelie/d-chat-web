@on_socket_get = (msg) ->
    console.log("got something")
    console.log(msg)

@run = ->
    console.log("run pressed")
    console.log(socket_connect("google.com", 80))
    socket_send("test")
