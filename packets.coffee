#= require <construct.coffee>

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
