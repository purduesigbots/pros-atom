querystring = require 'querystring'

# RFC1422-compliant Javascript UUID function. Generates a UUID from a random
# number (which means it might not be entirely unique, though it should be
# good enough for many uses). See http://stackoverflow.com/questions/105034
# (from https://gist.github.com/bmc/1893440)
generateUUID = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    r = Math.random() * 16 | 0
    v = if c is 'x' then r else (r & 0x3|0x8)
    v.toString(16)
  )

extend = (target, propertyMaps...) ->
  for propertyMap in propertyMaps
    for key, value of propertyMap
      target[key] = value
  target

module.exports =
  class GA
    @sendData: (sessionControl = 'start') ->
      params = {
        v: 1
        t: 'event'
        ec: 'session'
        ea: "#{sessionControl}_session"
        tid: 'UA-84548828-2'
        cid: atom.config.get 'pros.googleAnalytics.cid'
      }
      extend params,
        sc: sessionControl
      @post "https://google-analytics.com/collect?#{querystring.stringify params}"

    @post: (url) ->
      xhr = new XMLHttpRequest()
      console.log url
      xhr.open "POST", url
      xhr.send null

    @generateUUID: ->
      generateUUID()
