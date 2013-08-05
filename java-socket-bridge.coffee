java_socket_bridge_ready_flag = false


window.java_socket_bridge_set_ready = () ->

    java_socket_bridge_info("[js] java socket bridge ready")
    java_socket_bridge_ready_flag = true


window.java_socket_bridge_send = (msg) ->

    if java_socket_bridge_ready_flag

        java_socket_bridge_info("[js] sending -> " + msg)
        $("#JavaSocketBridge").get(0).send(msg)


window.java_socket_bridge_connect = (address, port) ->

    if java_socket_bridge_ready_flag

        java_socket_bridge_info("[js] connecting...")
        $("#JavaSocketBridge").get(0).connect(address, port)
        java_socket_bridge_info("[js] connected")


window.java_socket_bridge_on_receive = (msg) ->

    java_socket_bridge_info("[js] received -> " + msg)


window.java_socket_bridge_info = (msg) -> console.log(msg)


window.java_socket_bridge_error = (msg) -> console.log(msg)


window.java_socket_bridge_disconnect = () ->

    if java_socket_bridge_ready_flag

        java_socket_bridge_info("[js] disconnecting...")
        $("#JavaSocketBridge").get(0).disconnect()
        java_socket_bridge_info("[js] disconnected")
