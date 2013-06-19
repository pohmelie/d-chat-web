###
CoffeeScriptBinaryParser
###

class @bit32

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


class @construct

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

            return @__parse(new construct.DataIO(data))


        build: (data) ->

            return @__build(data, new construct.DataIO())


    class @BaseInt extends @Base

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
                num = BaseInt.signification(num, @size)

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


    class @CString extends @Base

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


    class @Struct extends @Base

        constructor: (@name, @objects...) ->

        __parse: (io, ctx={}) ->

            for object in @objects
                ctx[object.name] = object.__parse(io, {"_":ctx})

            return ctx


        __build: (ctx, io) ->

            for object in @objects
                object.__build(ctx[object.name], io)

            return io.data


bit32 = @bit32

log = (foo) ->
    try
        foo()
    catch e
        console.log(e)

log(() => new @construct.BaseInt("yoba", 0, "signed", "little"))
log(() => new @construct.BaseInt("yoba", "abc", "signed", "little"))
log(() => new @construct.BaseInt("yoba", 2, "ssigned", "little"))
log(() => new @construct.BaseInt("yoba", 2, "signed", "litttle"))

x = new @construct.BaseInt("SLInt16", 2, "signed", "little")
y = new @construct.BaseInt("SBInt16", 2, "signed", "big")

vars = [
    new @construct.BaseInt("SLInt16", 2, "signed", "little"),
    new @construct.BaseInt("SBInt16", 2, "signed", "big"),
    new @construct.BaseInt("ULInt16", 2, "unsigned", "little"),
    new @construct.BaseInt("UBInt16", 2, "unsigned", "big"),

    new @construct.BaseInt("SLInt32", 4, "signed", "little"),
    new @construct.BaseInt("SBInt32", 4, "signed", "big"),
    new @construct.BaseInt("ULInt32", 4, "unsigned", "little"),
    new @construct.BaseInt("UBInt32", 4, "unsigned", "big"),
]

for test in [[0xff, 0, 0xff, 0], [0, 0xff, 0, 0xff]]
    console.log("\ntest sequence ->", test)
    for v in vars
        parsed = v.parse(test)
        builded = v.build(parsed)
        console.log(v.name, parsed, builded)

s = new @construct.CString("CString")

ss = [
    [48, 49, 50, 0],
    [48, 49, 50],
    [0],
]

for test in ss
    console.log("\ntest sequence ->", test)
    #console.log(s.name, s.parse(test), s.build(s.parse(test)))
    log(() => console.log(s.name, s.parse(test), s.build(s.parse(test))))


s = new @construct.Struct(
    "test 1",
    new @construct.BaseInt("a", 2, "unsigned", "little"),
    new @construct.BaseInt("b", 2, "unsigned", "little"),
    new @construct.Struct(
        "test 2",
        new @construct.CString("string")
    )
)
data = [0xff, 0, 0, 0xff, 48, 49, 50, 0]
psd = s.parse(data)
bld = s.build(psd)

console.log("\n", psd, "\n", bld)
console.log(
    s.build({
        a:1,
        b:2,
        "test 2":{
            string:"hello"
        }
    })
)
