# coffee_state_machine.coffee - created 2012 by Wolfger Schramm <wolfger@spearwolf.de>

state_machine = (stateAttrName, options, fn) ->

    # options are optional
    if typeof options is 'function' and typeof fn is 'undefined'
        [fn, options] = [options, {}]

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

    # state helper function
    #
    valid_states = {}

    state_builder = (state) -> valid_states[state] or= {}
    state_builder.initial = (initialState) -> obj[stateAttrName] = initialState

    obj.is_valid_state = (state) -> valid_states[state]?

    # call given function within context of state object
    fn.call obj, state_builder

    return obj


# ===== CommonJS and AMD support ====== {{{
if typeof define is 'function' and define.amd
    define "state_machine", -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
