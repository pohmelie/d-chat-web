#= require <bit32.coffee>

class bnutil

    @alpha_map: [
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


    @hash_d2key: (cdkey, client_token, server_token) ->

        checksum = 0
        m_key = []

        for i in [0...cdkey.length] by 2
            n = bnutil.alpha_map[cdkey.charCodeAt(i)] * 24 + bnutil.alpha_map[cdkey.charCodeAt(i + 1)]
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
