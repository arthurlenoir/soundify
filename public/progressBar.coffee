class ProgressBar
    constructor: (@container, @strLabel = "", percentage = 0) ->
        @cursor = @container.find ".cursor"
        @label = @container.find ".label"
        @setProgress percentage

    setLabel: (label) ->
        @label.html label
        @cursor.html label

    setProgress: (percentage) ->
        if percentage == 100
            @setLabel @strLabel + ". Done."
        else
            @setLabel @strLabel + "&hellip;"
        @cursor.css "width", percentage + "%"

window.ProgressBar = ProgressBar