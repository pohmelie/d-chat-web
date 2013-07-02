#= require <ui.coffee>


$(() ->
    tabs = new Tabs("#tabs", "#chat", "#input")
    for i in [1..15]
        tabs.add("yoba" + i.toString())
)
