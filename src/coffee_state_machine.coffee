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


    # state helper function
    #
    all_states = {}

    create_state = (state, parent) ->
        state_def = all_states[state] or= state: state
        state_def.parent = parent if parent?

    state_builder = (state, options = {}) ->
        create_state state, options.parent
        create_state options.parent if options.parent?

    state_builder.type = 'coffee_state_machine.StateHelperFunction'
    state_builder.initial = (initialState) -> obj[stateAttrName] = initialState

    obj.is_valid_state = (state) -> all_states[state]?


    # event helper function
    #
    current_event = null

    event_builder = (event, callback) ->

        event_fn = obj[event] or= ->
            # TODO go through transisitions

        if typeof callback is 'function'
            current_event = event
            callback.call obj
            current_event = null

    event_builder.type = 'coffee_state_machine.EventHelperFunction'


    # transition helper function
    #
    transition_builder = (args...) ->
        # TODO create transisitions

    transition_builder.type = 'coffee_state_machine.TransitionHelperFunction'


    # call given function within context of state object
    fn.call obj, state_builder, event_builder, transition_builder

    # add state attribute to object
    obj[stateAttrName] or= options.initial

    # auto create state definition for initial state
    state_builder obj[stateAttrName]

    #obj.all_states = -> all_states

    return obj


# ===== CommonJS and AMD support ====== {{{
if typeof define is 'function' and define.amd
    define "state_machine", -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
