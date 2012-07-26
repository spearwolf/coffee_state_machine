
event_factory = ->
    return (eventName) ->
        console.log "create event:", eventName


state_machine = (stateAttrName, options, fn) ->

    # create new object from given class [ option -> 'class' ]
    #  or
    # create new or extend given object [ option -> 'extend' ]
    #
    if typeof options.class is 'function'
        obj = new options.class
    else
        obj = options.extend ? {}

    # add state attribute to object
    obj[stateAttrName] = options.initial ? "_unknown"

    # call given function within context of state object
    fn.call obj

    return obj


# ===== CommonJS and AMD support ====== {{{
if typeof define is 'function' and define.amd
    define "state_machine", -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
