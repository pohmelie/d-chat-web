#= require <ui.coffee>


$(() ->
    tabs = new Tabs("#tabs", "#chat", "#input")
    for i in [1..15]
        tabs.add("yoba" + i.toString())

    $("#input").on(
        "keydown",
        (e) =>
            if e.which == 13
                s = $("#input").val()
                tabs.echo("<div>#{s}</div>")
                $("#input").val("")
    )
)
