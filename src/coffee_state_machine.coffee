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
        return state_def

    state_builder = (state, options= {}, fn= undefined) ->
        [fn, options] = [options, {}] if typeof options is 'function'
        state_def = create_state state, options.parent
        state_def.properties = fn() if typeof fn is 'function'
        create_state options.parent if options.parent?

    state_builder.type = 'coffee_state_machine.StateHelperFunction'
    state_builder.initial = (initialState) -> obj[stateAttrName] = initialState

    obj.is_valid_state = (state) -> all_states[state]? and all_states[state].state is state

    set_new_state = (nextState) ->
        obj[stateAttrName] = nextState


    # event helper function
    #
    current_event = null

    event_builder = (event, callback) ->

        event_fn = obj[event] or= ->
            trans = event_fn.transitions[obj[stateAttrName]]
            set_new_state trans.to if trans?

        if typeof callback is 'function'
            current_event = event
            callback.call obj
            current_event = null

    event_builder.type = 'coffee_state_machine.EventHelperFunction'


    # transition helper function
    #
    create_event_transitions = (stateTransitionMap) ->
        event_func = obj[current_event]
        trans_map = event_func.transitions or= {}
        for onState, toState of stateTransitionMap
            trans_map[onState] = on: onState, to: toState

    transition_builder = (args...) ->
        # inside event definition?
        if current_event?
            create_event_transitions args[0] if typeof args[0] is 'object'

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
