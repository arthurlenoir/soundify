class NTP
    constructor: (@url, @precision = 10) ->
        @estimatedDiff = 0
        @estimatedRequestDelay = 0
        @estimatedResponseDelay = 0
        @estimations = []
        @estimationMap = {}
        @durations = []

    sync: (@totalIterations = 10) ->
        @simpleTest @totalIterations

    simpleTest: (iteration = 20) ->
        $(document).trigger "NPDProgress", Math.round 100 * (@totalIterations - iteration ) / @totalIterations
        if iteration > 0
            t1 = new Date().getTime()
            $.ajax
                url: @url
                data: 
                    t: t1
                success: (response) => 
                    t2 = new Date().getTime()
                    #$("body").append """<p>#{ t2 - t1 } - #{ response.split(':')[1] }</p>"""
                    duration = t2-t1
                    estimation = (parseInt response.split(':')[1], 10) - duration / 2
                    #@estimations.push estimation
                    @estimationMap[duration] = estimation
                    @durations.push duration
                    @simpleTest iteration - 1
        else
            sum = 0

            validDurations = @durations.slice().sort().slice 0, Math.floor @durations.length/2
            for duration, estimation of @estimationMap
                sum += estimation
                @estimations.push estimation
            @estimations.sort()
            @average = sum / @estimations.length
            @median = @estimations[Math.floor @estimations.length / 2]
            sum = 0
            for estim in @estimations
                sum += (Math.pow @average - estim, 2)
            @standardDeviation = Math.sqrt sum / @estimations.length
            $("body").append """<p>Average: #{ @average }<br />Median: #{ @median }<br />Standard Deviation: #{ @standardDeviation }</p>"""
            $(document).trigger "NTPReady"

    getTime: (iteration = @precision) ->
        t1 = @fixTime new Date().getTime()
        estimatedTime = t1 + @estimatedRequestDelay
        console.log "getTime(" + estimatedTime + ", " + iteration + ")"
        if iteration > 0
            $.ajax
                url: @url
                data: 
                    t: estimatedTime
                success: (response) => 
                    t2 = @fixTime new Date().getTime()
                    totalTime = t2 - t1
                    parsedResponse = response.split ':'
                    serverDate = parseInt parsedResponse[0], 10
                    if parsedResponse.length > 1
                        @estimatedRequestDelay = parseInt parsedResponse[1], 10
                        console.log "requestDelay" + @estimatedRequestDelay
                        @estimatedResponseDelay = totalTime - @estimatedRequestDelay
                    else
                        @estimatedRequestDelay = (totalTime / 2)
                        @estimatedResponseDelay = @estimatedRequestDelay
                    @estimatedDiff = serverDate - @estimatedRequestDelay - t1
                    console.log @estimatedDiff
                    $("body").append """<p>#{ @estimatedDiff }</p>"""
                    @getTime iteration - 1

    fixTime: (time) ->
        time + @median
window.NTP = NTP