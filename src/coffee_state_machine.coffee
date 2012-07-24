
event_factory = ->
    return (eventName) ->
        console.log "create event:", eventName


state_machine = (stateAttrName, options, fn) ->
    console.log "creating state_machine -->", stateAttrName, options
    fn()


# ===== CommonJS and AMD support ===== {{{
if typeof define is 'function' and define.amd
    define "state_machine", -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
