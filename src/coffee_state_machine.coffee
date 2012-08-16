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
    state_hooks = {}

    create_state = (state, parent) ->
        state_def = all_states[state] or= state: state
        state_def.parent = parent if parent?
        return state_def

    add_state_hooks = (hook, states, fn) ->
        states = [states] if typeof states is 'string'
        for state in states
            state_cb_def = state_hooks[state] or= {}
            state_cb_def[hook] or= []
            state_cb_def[hook].push fn

    state_builder = (state, options= {}, fn) ->
        [fn, options] = [options, {}] if typeof options is 'function'
        state_def = create_state state, options.parent
        state_def.properties = fn.call obj if typeof fn is 'function'
        create_state options.parent if options.parent?
        add_state_hooks "enter", state, options.enter if options.enter?
        add_state_hooks "exit", state, options.exit if options.exit?

    state_builder.initial = (initialState, options= {}, fn) ->
        state_builder initialState, options, fn
        obj[stateAttrName] = initialState

    state_builder.type = 'coffee_state_machine.StateHelperFunction'

    obj.is_valid_state = (state) -> all_states[state]? and all_states[state].state is state

    create_state_hook = (hook) ->
        (state..., options) ->
            fn = if typeof options is 'function' then options else options?.do
            add_state_hooks hook, state, fn

    state_builder.enter = create_state_hook "enter"
    state_builder.exit = create_state_hook "exit"

    origProperties = {}

    call_state_hooks = (state, hook) ->
        parent_state = all_states[state]?.parent
        call_state_hooks parent_state, hook if parent_state?
        hook_fns = state_hooks[state]?[hook] or []
        fn.call obj for fn in hook_fns

    set_new_state = (nextState, oldState= obj[stateAttrName]) ->
        obj[stateAttrName] = nextState
        # restore previously backuped properties
        obj[k] = v for own k, v of origProperties
        # set properties and methods from new state
        for own k, v of all_states[nextState].properties
            [origProperties[k], obj[k]] = [obj[k], v]
        # TODO don't forget the parents!
        # invoke state hooks
        if oldState? and nextState isnt oldState
            call_state_hooks oldState, "exit"
        if oldState is false or nextState isnt oldState
            call_state_hooks nextState, "enter"


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
    set_new_state obj[stateAttrName], false

    return obj


# ===== CommonJS and AMD support ====== {{{
if typeof define is 'function' and define.amd
    define "state_machine", -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
