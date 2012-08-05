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
        state_def.properties = fn.call obj if typeof fn is 'function'
        create_state options.parent if options.parent?

    state_builder.type = 'coffee_state_machine.StateHelperFunction'
    state_builder.initial = (initialState) -> obj[stateAttrName] = initialState

    obj.is_valid_state = (state) -> all_states[state]? and all_states[state].state is state

    origProperties = {}

    set_new_state = (nextState) ->
        obj[stateAttrName] = nextState
        # restore previously backuped properties
        obj[k] = v for own k, v of origProperties
        # use properties and methods from new state
        for own k, v of all_states[nextState].properties
            [origProperties[k], obj[k]] = [obj[k], v]


    # event helper function
    #
    current_event = null

    event_builder = (event, callback) ->

        event_fn = obj[event] or= ->
            trans = event_fn.transitions[obj[stateAttrName]]
            if trans?
                perform_switch = yes
                if typeof trans.if is 'function'
                    perform_switch = trans.if.call obj
                set_new_state trans.to if perform_switch

        if typeof callback is 'function'
            current_event = event
            callback.call obj
            current_event = null

    event_builder.type = 'coffee_state_machine.EventHelperFunction'


    # transition helper function
    #
    create_state_trans_def = (onState, toState, ifCallback) ->
        trans_def = on: onState, to: toState
        trans_def.if = ifCallback if typeof ifCallback is 'function'
        return trans_def

    current_state_transitions = ->
        event_func = obj[current_event]
        event_func.transitions or= {}

    create_state_transitions = (stateTransitionMap) ->
        trans_map = current_state_transitions()
        for onState, toState of stateTransitionMap
            trans_map[onState] = create_state_trans_def onState, toState

    transition_builder = (args...) ->
        # inside event definition?
        if current_event?
            if typeof args[0] is 'object' and args.length is 1
                create_state_transitions args[0]

    transition_builder.on = (onState, options = {}) ->
        # inside event definition?
        if current_event?
            trans_map = current_state_transitions()
            trans_map[onState] = create_state_trans_def onState, options.to, options.if

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
