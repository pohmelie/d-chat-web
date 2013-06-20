class bit32

    @make_signed: (n) ->

        return (n & 0xffffffff) << 0


    @make_unsigned: (n) ->

        return (n & 0xffffffff) >>> 0


    @shr: (n, s) ->

        if s >= 32
            return 0
        else
            return @make_unsigned(n >>> s)


    @shl: (n, s) ->

        if s >= 32
            return 0
        else
            return @make_unsigned(n << s)


    @ror: (n, s) ->

        return @make_unsigned(@shr(n, s % 32) | @shl(n, 32 - (s % 32)))


    @rol: (n, s) ->

        return @make_unsigned(@shr(n, 32 - (s % 32)) | @shl(n, s % 32))



class xsha1

    @bsha1: (data) ->

        return @pack(@calc_hash_buffer(data)...)


    @pack: (args...) ->

        ret = []
        for arg in args
            for i in [0..3]
                ret.push(arg & 0xff)
                arg = bit32.shr(arg, 8)
        return ret


    @insert_byte: (buf, loc, b) ->

        the_int = Math.floor(loc / 4)
        the_byte = loc % 4
        buf[the_int] = (buf[the_int] & (bit32.shl(0xFF, (8 * the_byte)) ^ 0xFFFFFFFF)) | bit32.shl(b, (8 * the_byte))


    @calc_hash_buffer: (hash_data) ->

        hash_buffer = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0]
        for i in [1..0x10]
            hash_buffer.push(0)

        i = 0
        while i < hash_data.length
            sub_len = hash_data.length - i

            if sub_len > 0x40
                sub_len = 0x40

            j = 0
            while j < sub_len
                @insert_byte(hash_buffer, j + 20, hash_data[j + i])
                j += 1

            if sub_len < 0x40
                j = sub_len
                while j < 0x40
                    @insert_byte(hash_buffer, j + 20, 0)
                    j += 1

            @do_hash(hash_buffer)

            i += 0x40

        return hash_buffer[0..4]


    @do_hash: (hash_buffer) ->

        buf = []
        for i in [1..0x50]
            buf.push(0)

        i = 0
        while i < 0x10
            buf[i] = hash_buffer[i + 5]
            i += 1

        while i < 0x50
            dw = buf[i - 0x3] ^ buf[i - 0x8] ^ buf[i - 0x10] ^ buf[i - 0xE]
            buf[i] = bit32.rol(1, dw & 0x1f)
            i += 1

        [a, b, c, d, e] = hash_buffer[0..4].map(bit32.make_unsigned)
        p = 0

        while p < 20
            dw = bit32.rol(a, 5) + bit32.make_unsigned((~b & d) | (c & b)) + e + buf[p] + 0x5a827999
            dw = bit32.make_unsigned(dw)
            e = d
            d = c
            c = bit32.make_unsigned(bit32.rol(b, 0x1E))
            b = a
            a = dw
            p += 1
            i += 1

        while p < 40
            dw = bit32.make_unsigned(d ^ c ^ b) + e + bit32.rol(a, 5) + buf[p] + 0x6ED9EBA1
            dw = bit32.make_unsigned(dw)
            e = d
            d = c
            c = bit32.make_unsigned(bit32.rol(b, 0x1E))
            b = a
            a = dw
            p += 1

        while p < 60
            dw = bit32.make_unsigned((c & b) | (d & c) | (d & b)) + e + bit32.rol(a, 5) + buf[p] - 0x70E44324
            dw = bit32.make_unsigned(dw)
            e = d
            d = c
            c = bit32.make_unsigned(bit32.rol(b, 0x1E))
            b = a
            a = dw
            p += 1

        while p < 80
            dw = bit32.rol(a, 5) + e + bit32.make_unsigned(d ^ c ^ b) + buf[p] - 0x359D3E2A
            dw = bit32.make_unsigned(dw)
            e = d
            d = c
            c = bit32.make_unsigned(bit32.rol(b, 0x1E))
            b = a
            a = dw
            p += 1

        for i in [0..4]
            hash_buffer[i] = bit32.make_unsigned(hash_buffer[i] + [a, b, c, d, e][i])



class construct

    @copy: (obj, visited=[]) ->

        if typeof(obj) isnt "object"
            return obj

        for [r, c] in visited
            if r is obj
                return c

        c = {}
        visited.push([obj, c])
        for k, v of obj
            c[k] = @copy(v, visited)

        return c


    class @DataIO

        constructor: (@data=[], @shift=0) ->

        read: () ->

            if @shift == @data.length
                throw new Error("DataReader: end of data")

            return @data[@shift++]


        tail: () ->

            return @data[@shift...@data.length]


        write: (bytes) ->

            @data.push(bytes...)
            return @data


    class @Base

        parse: (data) ->

            ctx = {}
            ctx["_"] = ctx
            return @__parse(new construct.DataIO(data), ctx)


        build: (data) ->

            return @__build(data, new construct.DataIO())


    class @_BaseInt extends @Base

        constructor: (@name, @size, @signed, @endian) ->

            if typeof(@size) isnt "number" or @size < 1
                throw new Error("BaseInt (name = '#{@name}'): bad size ('#{@size}')")

            if @signed not in ["signed", "unsigned"]
                throw new Error("BaseInt (name = '#{@name}'): bad sign ('#{@signed}')")

            if @endian not in ["little", "big"]
                throw new Error("BaseInt (name = '#{@name}'): bad endian ('#{@endian}')")


        @signification: (num, size) ->

            if num & Math.pow(2, size * 8 - 1)
                return bit32.make_unsigned(num) - Math.pow(2, size * 8)
            else
                return bit32.make_unsigned(num)


        __parse: (io) ->

            data = (io.read() for i in [1..@size])

            if @endian is "big"
                [head, tail, step] = [0, @size - 1, 1]
            else if @endian is "little"
                [head, tail, step] = [@size - 1, 0, -1]

            num = 0
            for i in [head..tail] by step
                if data[i]?
                    num = bit32.make_unsigned(bit32.shl(num, 8) | data[i])
                else
                    throw new Error("BaseInt (name = '#{@name}'), bad data")

            if @signed is "signed"
                num = _BaseInt.signification(num, @size)

            return num


        __build: (num, io) ->

            data = []
            num = bit32.make_unsigned(num)
            for i in [1..@size]
                data.push(num & 0xff)
                num = bit32.shr(num, 8)

            if @endian is "big"
                data.reverse()

            return io.write(data)


    class @_CString extends @Base

        constructor: (@name) ->

        __parse: (io) ->

            data = []
            try
                while (ch = io.read()) != 0
                    data.push(ch)

                return String.fromCharCode(data...)

            catch error
                throw new Error("CString, unexpected end of data")


        __build: (string, io) ->

            io.write((string.charCodeAt(i) for i in [0...string.length]))
            return io.write([0])


    class @_Struct extends @Base

        constructor: (@name, @objects...) ->

        __parse: (io, ctx) ->

            for object in @objects
                parsed = object.__parse(io, {"_":ctx})
                if object.name?
                    ctx[object.name] = parsed

            return ctx


        __build: (ctx, io) ->

            for object in @objects
                object.__build(ctx[object.name] or ctx, io)

            return io.data


    class @_Enum extends @Base

        constructor: (@object, @values) ->

            @name = @object.name


        __parse: (io) ->

            parsed = @object.__parse(io)

            if @values[parsed]?
                return @values[parsed]
            else
                throw new Error("Enum: value not in list (#{parsed})")


        __build: (value, io) ->

            for k, v of @values
                if value == v
                    return @object.__build(k, io)

            throw new Error("Enum: value not in list (#{ctx[@name]})")


    class @_Const extends @Base

        constructor: (@object, @value) ->
            @name = @object.name


        __parse: (io) ->

            parsed = @object.__parse(io)

            if parsed == @value
                return @value
            else
                throw new Error("Const: expect (#{@value}), but got (#{parsed})")

        __build: (nothing, io) ->

            return @object.__build(@value, io)


    class @_Embedded extends @Base

        constructor: (@object) ->

        __parse: (io, ctx) ->

            return @object.__parse(io, ctx["_"])


        __build: (ctx, io) ->

            return @object.__build(ctx, io)


    class @_Switch extends @Base

        constructor: (@f, @objects) ->

        __parse: (io, ctx) ->

            ctx = ctx["_"]
            object = @objects[@f(ctx)] or @objects.default

            if object?
                ctx[object.name] = object.__parse(io, ctx)
                return ctx
            else
                throw new Error("Switch: there is no (#{@f(ctx)}) key or 'default'")


        __build: (ctx, io) ->

            object = @objects[@f(ctx)] or @objects.default

            if object?
                return object.__build(ctx[object.name] or ctx, io)
            else
                throw new Error("Switch: there is no (#{@f(ctx)}) key or 'default'")


    class @_Pass extends @Base

        __parse: (io, ctx) ->

            return ctx


        __build: (ctx, io) ->

            return io.data


    class @_OptionalGreedyRange extends @Base

        constructor: (@object) ->
            @name = @object.name


        __parse: (io, ctx) ->

            ctxs = []
            io_position = io.shift

            try
                while true
                    io_position = io.shift
                    ctxs.push(@object.__parse(io, construct.copy(ctx)))
            catch error
                io.shift = io_position

            return ctxs


        __build: (ctxs, io) ->

            for ctx in ctxs
                @object.__build(ctx, io)

            return io.data


    class @_Array extends @Base

        constructor: (cnt, @object) ->

            @name = @object.name

            if typeof(cnt) is "number"
                @count = () -> cnt
            else
                @count = cnt


        __parse: (io, ctx) ->

            ctxs = []
            for i in [1..@count(ctx)]
                ctxs.push(@object.__parse(io, construct.copy(ctx)))

            return ctxs


        __build: (ctxs, io) ->

            if ctxs.length != @count(ctxs[0])
                throw new Error("Array: count of objects (#{ctxs.length}) doesn't matches #{@count()}")

            for ctx in ctxs
                @object.__build(ctx, io)

            return io.data


    class @_Adapter extends @Base

        constructor: (@object,  @parser, @builder) ->


        __parse: (io, ctx) ->

            return @parser(@object.__parse(io, ctx), ctx)


        __build: (ctx, io) ->

            return @object.build(@builder(ctx), io)


    @str2bin: (str) ->

        return (str.charCodeAt(i) for i in [0...str.length])


    # shorthands for similar creation of "base" classes and "complex" ones

    @BaseInt: (args...) -> new @_BaseInt(args...)
    @CString: (args...) -> new @_CString(args...)
    @Struct: (args...) -> new @_Struct(args...)
    @Enum: (args...) -> new @_Enum(args...)
    @Const: (args...) -> new @_Const(args...)
    @Embedded: (args...) -> new @_Embedded(args...)
    @Switch: (args...) -> new @_Switch(args...)
    @Pass: (args...) -> new @_Pass(args...)
    @OptionalGreedyRange: (args...) -> new @_OptionalGreedyRange(args...)
    @Array: (args...) -> new @_Array(args...)
    @Adapter: (args...) -> new @_Adapter(args...)

    @EmbedStruct: (objecsts...) -> @Embedded(@Struct(null, objecsts...))
    @Tail: (name="tail") -> @OptionalGreedyRange(@ULInt8(name))
    @Bytes: (name, count) -> @Array(count, @ULInt8(name))

    @ULInt8: (name) -> @BaseInt(name, 1, "unsigned", "little")
    @ULInt16: (name) -> @BaseInt(name, 2, "unsigned", "little")
    @ULInt32: (name) -> @BaseInt(name, 4, "unsigned", "little")

    @UBInt8: (name) -> @BaseInt(name, 1, "unsigned", "big")
    @UBInt16: (name) -> @BaseInt(name, 2, "unsigned", "big")
    @UBInt32: (name) -> @BaseInt(name, 4, "unsigned", "big")

    @SLInt8: (name) -> @BaseInt(name, 1, "signed", "little")
    @SLInt16: (name) -> @BaseInt(name, 2, "signed", "little")
    @SLInt32: (name) -> @BaseInt(name, 4, "signed", "little")

    @SBInt8: (name) -> @BaseInt(name, 1, "signed", "big")
    @SBInt16: (name) -> @BaseInt(name, 2, "signed", "big")
    @SBInt32: (name) -> @BaseInt(name, 4, "signed", "big")


s = construct.Struct(
    "test 1",
    construct.ULInt16("a")
    construct.ULInt16("b")
    construct.EmbedStruct(construct.CString("string")),
    construct.Enum(
        construct.ULInt8("some_enum")
        {
            0:"zero",
            1:"one",
            2:"two"
        }
    )
    construct.Const(construct.ULInt8("with_name1"), 33),
    construct.Const(construct.ULInt8(null), 33),
    construct.Const(construct.ULInt8("with_name2"), 34),
    construct.Const(construct.ULInt8(null), 34),
    construct.Switch(
        (ctx) -> ctx.some_enum,
        {
            one:construct.ULInt8("switch1"),
            two:construct.ULInt16("switch2"),
            default:construct.Pass(),
        }
    )
)
data = [0xff, 0, 0, 0xff, 48, 49, 50, 0, 2, 33, 33, 34, 34, 0xfe, 0xff, 0x01]
psd = s.parse(data)
bld = s.build(psd)

console.log("\n", psd, "\n", bld)

construct.copy([1, 2, 3])
gr = construct.Struct(
    null,
    construct.ULInt8("count")
    construct.Array(
        (ctx) -> ctx["_"].count,
        construct.Struct(
            "blah"
            construct.ULInt8("low"),
            construct.ULInt8("high"),
        )
    ),
    construct.Tail()
)
console.log("\n")
psd = gr.parse([2, 1, 2, 3, 4, 5, 6])
console.log(psd)
bld = gr.build(psd)
console.log(bld)

ad = construct.Adapter(
    construct.ULInt8("x"),
    (ctx) -> ctx + 1,
    (ctx) -> ctx - 1
)

p = ad.parse([1])
console.log(p)
b = ad.build(p)
console.log(b)



class packets
    @_spacket: construct.Struct(
        null,
        construct.Const(construct.ULInt8(null), 0xff),
        construct.Enum(
            construct.ULInt8("packet_id"),
            {
                0x50:"SID_AUTH_INFO",
                0x25:"SID_PING",
                0x51:"SID_AUTH_CHECK",
                0x3a:"SID_LOGONRESPONSE2",
                0x0a:"SID_ENTERCHAT",
                0x0b:"SID_GETCHANNELLIST",
                0x0c:"SID_JOINCHANNEL",
                0x0e:"SID_CHATCOMMAND",
            }
        ),
        construct.ULInt16("length"),
        construct.Switch(
            (ctx) -> ctx.packet_id,
            {
                "SID_AUTH_INFO": construct.EmbedStruct(
                    construct.ULInt32("protocol_id"),
                    construct.Bytes("platform_id", 4),
                    construct.Bytes("product_id", 4),
                    construct.ULInt32("version_byte"),
                    construct.Bytes("product_language", 4),
                    construct.Bytes("local_ip", 4),
                    construct.SLInt32("time_zone"),
                    construct.ULInt32("locale_id"),
                    construct.ULInt32("language_id"),
                    construct.CString("country_abreviation"),
                    construct.CString("country")
                ),
                "SID_PING": construct.EmbedStruct(
                    construct.ULInt32("value"),
                ),
                "SID_AUTH_CHECK": construct.EmbedStruct(
                    construct.ULInt32("client_token"),
                    construct.ULInt32("exe_version"),
                    construct.ULInt32("exe_hash"),
                    construct.ULInt32("number_of_cd_keys"),
                    construct.ULInt32("spawn_cd_key"),
                    construct.Array(
                        (ctx) -> ctx["_"].number_of_cd_keys,
                        construct.Struct(
                            "cd_keys",
                            construct.ULInt32("key_length"),
                            construct.ULInt32("cd_key_product"),
                            construct.ULInt32("cd_key_public"),
                            construct.Const(construct.ULInt32(null), 0),
                            construct.Bytes("hash", 5 * 4),
                        )
                    ),
                    construct.CString("exe_info"),
                    construct.CString("cd_key_owner")
                ),
                "SID_LOGONRESPONSE2": construct.EmbedStruct(
                    construct.ULInt32("client_token"),
                    construct.ULInt32("server_token"),
                    construct.Bytes("hash", 5 * 4),
                    construct.CString("username"),
                ),
                "SID_ENTERCHAT": construct.EmbedStruct(
                    construct.CString("username"),
                    construct.CString("statstring"),
                ),
                "SID_GETCHANNELLIST": construct.EmbedStruct(
                    construct.Bytes("product_id", 4),
                ),
                "SID_JOINCHANNEL": construct.EmbedStruct(
                    construct.ULInt32("unknown"),
                    construct.CString("channel_name"),
                ),
                "SID_CHATCOMMAND": construct.EmbedStruct(
                    construct.CString("text"),
                ),
            }
        )
    )

    @spacket: construct.Adapter(  # client -> server
        packets._spacket,
        (ctx) -> ctx,
        (ctx) ->
            ctx.length = 0
            ctx.length = packets._spacket.build(ctx).length
            return ctx
    )

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



p01 = packets.spacket.build({
    packet_id:"SID_AUTH_INFO",
    protocol_id:0,
    platform_id:construct.str2bin('68XI'),
    product_id:construct.str2bin('PX2D'),
    version_byte:13,
    product_language:construct.str2bin('SUne'),
    local_ip:[192, 168, 0, 100],
    time_zone:0,
    locale_id:1049,
    language_id:1049,
    country_abreviation:'RUS',
    country:'Russia'
})

console.log(p01)



mpq_hash_codes = [
    0xE7F4CB62,
    0xF6A14FFC,
    0xAA5504AF,
    0x871FCDC2,
    0x11BF6A18,
    0xC57292E6,
    0x7927D27E,
    0x2FEC8733
]

alpha_map = [
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF,	0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x00, 0xFF, 0x01, 0xFF, 0x02, 0x03,
        0x04, 0x05, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
        0x0C, 0xFF, 0x0D, 0x0E, 0xFF, 0x0F, 0x10, 0xFF,
        0x11, 0xFF,	0x12, 0xFF, 0x13, 0xFF, 0x14, 0x15,
        0x16, 0xFF, 0x17, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
        0x0C, 0xFF, 0x0D, 0x0E, 0xFF, 0x0F, 0x10, 0xFF,
        0x11, 0xFF, 0x12, 0xFF, 0x13, 0xFF, 0x14, 0x15,
        0x16, 0xFF, 0x17, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF,	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
    ]


class bnutil

    @check_revision: (formula, mpq) ->

        mpq_hash = mpq_hash_codes[Number(mpq[9])]
        exprs = formula.split(" ")
        init = exprs[0..2].join(";") + ";"

        body = ""
        for i in [4...(4 + Number(exprs[3]))]
            [k, v] = exprs[i].split("=")
            body += "#{k}=bit32.make_unsigned(#{v});"

        A = B = C = S = i = 0
        body = "for(i = 0; i != binaries.length; i++){S = binaries[i];" + body + "}"
        eval(init)
        A ^= mpq_hash
        eval(body)

        return C


    @hash_d2key: (cdkey, client_token, server_token) ->

        checksum = 0
        m_key = []

        for i in [0...cdkey.length] by 2
            n = alpha_map[cdkey.charCodeAt(i)] * 24 + alpha_map[cdkey.charCodeAt(i + 1)]
            if n >= 0x100
                n -= 0x100
                checksum = bit32.make_unsigned(checksum | bit32.shl(1, bit32.shr(i, 1)))
            m_key[i] = bit32.make_unsigned(bit32.shr(n, 4) & 0xf).toString(16).toUpperCase()
            m_key[i + 1] = bit32.make_unsigned(n & 0xf).toString(16).toUpperCase()

        if m_key.reduce(((v, ch) -> (v + (parseInt(ch, 16) ^ (v * 2))) & 0xff), 3) != checksum
            return  # invalid CD-key

        for i in [(cdkey.length - 1)..0] by -1
            n = (i - 9) & 0xf
            [m_key[i], m_key[n]] = [m_key[n], m_key[i]]

        v2 = 0x13AC9741
        for i in [(cdkey.length - 1)..0] by -1
            t = parseInt(m_key[i], 16)
            if t <= 7
                m_key[i] = String.fromCharCode((v2 & 7) ^ m_key[i].charCodeAt(0))
                v2 = bit32.shr(v2, 3)
            else if t < 10
                m_key[i] = String.fromCharCode((i & 1) ^ m_key[i].charCodeAt(0))

        m_key = m_key.join("")
        public_value = parseInt(m_key[2..7], 16)
        hash_data = xsha1.pack(
            client_token,
            server_token,
            parseInt(m_key[0..1], 16),
            public_value,
            0,
            parseInt(m_key[8..15], 16)
        )

        return [public_value, xsha1.bsha1(hash_data)]


    @sub_double_hash: (client_token, server_token, hashpass) ->

        return xsha1.bsha1(xsha1.pack(client_token, server_token).concat(hashpass))

