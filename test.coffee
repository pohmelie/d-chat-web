@on_socket_get = (msg) ->
    console.log("got something [", msg, "]")

@run = ->
    console.log("run pressed")
    socket_connect("rubattle.net", 6112)
    socket_send("01")

console.log("hi")
