crypto = require 'crypto'
fs = require 'fs'
http = require 'http'
path = require 'path'
url = require 'url'

pools = {}
userToPool = {}

getPlayTime = (d) ->
    playAt = (Math.floor((d + 60000) / 60000) + 1) * 60000
    playIn = playAt - d
    [playAt, playIn]

cleanPools = ->
    toDelete = []
    for name, pool of pools
        if pool.startDate? and pool.startDate < new Date().getTime()
            toDelete.push name
    for name in toDelete
        delete pools[name]
    

http.createServer (request, response) ->
    console.log request.url

    filePath = '.' + request.url
    if filePath == './'
        filePath = './test.html'

    extname = path.extname filePath
    contentType = switch extname
        when '.js' then 'text/javascript'
        when '.css' then 'text/css'
        when '.html' then 'text/html'
        when '.mp3' then 'audio/mpeg'
        when '.ogg' then 'audio/ogg'
        when '.json' then 'application/json'
        else 'text/plain'

    urlParts = url.parse request.url, true

    path.exists filePath, (exists) ->
        if exists
            fs.readFile filePath, (error, content) ->
                if error
                    response.writeHead 500
                    response.end()
                else
                    response.writeHead 200, 
                        'Content-Type': contentType
                    if contentType in ['audio/mpeg', 'audio/ogg']
                        response.end content
                    else
                        response.end content, 'utf-8'
        else if urlParts.pathname == "/ntp"
            response.writeHead 200, 
                'Content-Type': contentType
            d = new Date().getTime()
            answer = "" + d 
            if urlParts.query?.t?
                estimatedDate = parseInt urlParts.query.t, 10
                answer += ":" + (answer - estimatedDate)
            response.end answer
        else if urlParts.pathname == "/sync" and urlParts.query?.t?
            d = new Date().getTime()
            delay = parseInt urlParts.query.t, 10
            [playAt, playIn] = getPlayTime d
            playIn -= delay
            setTimeout ( -> 
                response.end()
                ), playIn
        else if urlParts.pathname == "/presync"
            d = new Date().getTime()
            [playAt, playIn] = getPlayTime d
            response.end "" + playIn
        else if urlParts.pathname == "/connect"
            sha1 = crypto.createHash 'sha1'
            sha1.update "" + new Date().getTime()
            hash = sha1.digest 'base64'
            response.end hash
        else if urlParts.pathname == "/join.json" and urlParts.query?.name? and urlParts.query?.user? and urlParts.query?.hash?
            name = urlParts.query.name
            user = urlParts.query.user
            hash = urlParts.query.hash
            if not pools[name]?
                console.log "new pool"
                pools[name] = 
                    members: []
                    startDate: null
                    master: hash
            if userToPool[hash]? and userToPool[hash] != name and pools[userToPool[hash]]?
                for i, member of pools[userToPool[hash]].members
                    console.log i, typeof i, member
                    if member.hash == hash
                        console.log "user change pool"
                        pools[userToPool[hash]].members.splice (parseInt i, 10), 1
                        break
            if userToPool[hash] != name
                userToPool[hash] = name
                pools[name].members.push
                    hash: hash
                    name: user
            if urlParts.query.start and not pools[name].startDate?
                pools[name].startDate = new Date().getTime() + 4500
            response.end JSON.stringify pools
            console.log "cleanPools"
            cleanPools()
        else if urlParts.pathname == "/pools.json"
            cleanPools()
            response.end JSON.stringify pools
        else
            response.writeHead 404
            response.end()
.listen 80, '0.0.0.0'
console.log 'Server running at http://127.0.0.1:80/'