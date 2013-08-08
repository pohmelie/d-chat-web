class Autocomplete

    constructor: (@words = []) ->

        @words.sort()


    add: (word) ->

        if not (word in @words)
            @words.push(word)
            @words.sort()


    remove: (word) ->

        @words = @words.filter((w) -> w != word)


    filter: (msg) ->

        word = msg.split(" ").pop()
        return @words.filter((w) -> w.indexOf(word) == 0 and w isnt word)


    cut: (msg, word) ->

        return word[msg.split(" ").pop().length..-1]
