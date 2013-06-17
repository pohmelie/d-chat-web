class @xsha1
    @bsha1: (data) ->
        ret = []
        for el in @calc_hash_buffer(data)
            for i in [1..4]
                ret.push(el & 0xff)
                el = bit32.shr(el, 8)
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

        #Used to assign directly from list, until I found the value of uint32
        a = bit32.make_unsigned(hash_buffer[0])
        b = bit32.make_unsigned(hash_buffer[1])
        c = bit32.make_unsigned(hash_buffer[2])
        d = bit32.make_unsigned(hash_buffer[3])
        e = bit32.make_unsigned(hash_buffer[4])
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

        hash_buffer[0] = bit32.make_unsigned(hash_buffer[0] + a)
        hash_buffer[1] = bit32.make_unsigned(hash_buffer[1] + b)
        hash_buffer[2] = bit32.make_unsigned(hash_buffer[2] + c)
        hash_buffer[3] = bit32.make_unsigned(hash_buffer[3] + d)
        hash_buffer[4] = bit32.make_unsigned(hash_buffer[4] + e)
