###
@on_socket_get = (msg) ->
    console.log("got something [", msg, "]")

@run = ->
    console.log("run pressed")
    socket_connect("rubattle.net", 6112)
    socket_send("01")
###

#console.log(xsha1.bsha1([0..9]))

data = [0xff, 0xff00, 0xff0000, 0xff000000]

s = "A=803935755 B=3407199954 C=3485268447 4 A=A^S B=B+C C=C^A A=A-B"

exprs = s.split(" ")
init = exprs[0..2].join(";") + ";"

body = ""
for i in [4...(4 + Number(exprs[3]))]
    [k, v] = exprs[i].split("=")
    body += "#{k}=bit32.make_unsigned(#{v});"

console.log(init, body)
A = B = C = 0
eval(init)
for S in data
    eval(body)
    console.log(A, B, C, S)

@run = ->
    f = document.getElementById("JavaFileReaderBridge")
    console.log(f.open("d2xp/Game.exe"))
    console.log(f.length())
