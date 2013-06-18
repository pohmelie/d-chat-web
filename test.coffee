###
@on_socket_get = (msg) ->
    console.log("got something [", msg, "]")

@run = ->
    console.log("run pressed")
    socket_connect("rubattle.net", 6112)
    socket_send("01")
###
###
console.log(xsha1.bsha1([0..9]).map((x) -> x.toString(16)).join(" "))
console.log(
    bnutil.check_revision(
        'A=803935755 B=3407199954 C=3485268447 4 A=A^S B=B+C C=C^A A=A-B',
        'ver-IX86-3.mpq'
    )
)
[pb, hs] = bnutil.hash_d2key("DPTGEGHRPH4EB7EV", 666, 1557451278)
console.log(pb, hs.map((x) -> x.toString(16)).join(" "))

pass = "yoba"
sdhs = bnutil.sub_double_hash(666, 1557451278, xsha1.bsha1(pass.charCodeAt(i) for i in [0...pass.length]))
console.log(sdhs.map((x) -> x.toString(16)).join(" "))
###
