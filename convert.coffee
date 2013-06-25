class convert

    @bin2str: (bin) ->

        return String.fromCharCode(bin...)


    @str2bin: (str) ->

        return (str.charCodeAt(i) for i in [0..])


    @bin2hex: (bin) ->

        sizer = (s) ->
            if s.length == 1
                return "0" + s
            else
                return s

        return bin.map((x) -> sizer(x.toString(16))).join(" ")


    @hex2bin: (hex) ->

        return hex.split(" ").map((x) -> parseInt(x, 16))
