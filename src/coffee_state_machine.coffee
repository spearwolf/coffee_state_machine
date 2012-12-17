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
        #(state..., options) ->
        (state..., fn) ->
            #fn = if typeof options is 'function' then options else options?.action
            #add_state_hooks hook, state, fn
            add_state_hooks hook, state, fn

    state_builder.enter = create_state_hook "enter"
    state_builder.exit = create_state_hook "exit"

    origProperties = {}

    get_parent_state = (state) -> all_states[state]?.parent

    get_parent_states = (state) ->
        if state_def = all_states[state]?
            state_def.parents or= (state while state = get_parent_state state).reverse()
        else
            []

    obj.get_parent_states = (state) -> get_parent_states state

    foreach_parent_states = (state, fn) ->
        fn(state) for state in get_parent_states(state)
        return

    call_state_hooks = (state, hook) ->
        hook_fns = state_hooks[state]?[hook] or []
        fn.call obj for fn in hook_fns

    extend_obj_with = (props) ->
        [origProperties[k], obj[k]] = [obj[k], v] for own k, v of props
        return

    extend_with_own = (props, o) ->
        o[k] = v for own k, v of props
        return

    set_new_state = (nextState, oldState= obj[stateAttrName]) ->
        parents =
            old: get_parent_states oldState
            next: get_parent_states nextState

        parents.exit = (state for state in parents.old when parents.next.indexOf(state) is -1)
        parents.enter = (state for state in parents.next when parents.old.indexOf(state) is -1)

        # exit hooks
        call_state_hooks state, "exit" for state in parents.exit when state isnt nextState
        call_state_hooks oldState, "exit" if (oldState? and nextState isnt oldState) and parents.next.indexOf(oldState) is -1

        # set new state ..
        obj[stateAttrName] = nextState

        # restore previously backuped properties
        obj[k] = v for own k, v of origProperties

        # set properties and methods from new state (and parents..)
        new_props = {}
        foreach_parent_states nextState, (state) ->
            extend_with_own all_states[state].properties, new_props
        extend_with_own all_states[nextState].properties, new_props
        extend_obj_with new_props

        # enter hooks
        call_state_hooks state, "enter" for state in parents.enter when state isnt oldState
        call_state_hooks nextState, "enter" if (oldState is false or nextState isnt oldState) and parents.old.indexOf(nextState) is -1


    # event helper function
    #
    current_event = null

    event_builder = (event, callback) ->

        event_fn = obj[event] or= (args...) ->
            trans = event_fn.transitions[obj[stateAttrName]]
            if trans?
                if trans.if?
                    perform_switch = trans.if.call obj
                else
                    perform_switch = yes

                if perform_switch
                    if trans.unless?
                        perform_switch = not trans.unless.call(obj)
                    if perform_switch
                        oldState = obj[stateAttrName]
                        set_new_state trans.to

                        # collect transition hooks from parents
                        trans_hooks = []
                        for par_state in get_parent_states(oldState)
                            par_trans = event_fn.transitions[par_state]
                            if par_trans?
                                if par_trans.action? and par_trans.to is obj[stateAttrName] or get_parent_states(obj[stateAttrName]).indexOf(par_trans.to) isnt -1
                                    trans_hooks.push par_trans.action
                        if trans.action?
                            trans_hooks.push trans.action

                        # call transition hooks
                        trans_hooks_called = []
                        for hook in trans_hooks when trans_hooks_called.indexOf(hook) is -1
                            hook.apply obj, [oldState].concat args
                            trans_hooks_called.push hook

                        return true

            return false  # no transition found

        if typeof callback is 'function'
            current_event = event
            callback.call obj
            current_event = null

    event_builder.type = 'coffee_state_machine.EventHelperFunction'


    # transition helper function
    #
    create_state_trans_def = (onState, toState, ifCallback, unlessCallback, doAction) ->
        trans_def = from: onState, to: toState
        trans_def.if = ifCallback if typeof ifCallback is 'function'
        trans_def.unless = unlessCallback if typeof unlessCallback is 'function'
        trans_def.action = doAction if typeof doAction is 'function'
        return trans_def

    current_state_transitions = ->
        event_func = obj[current_event]
        event_func.transitions or= {}

    create_state_transitions = (stateTransitionMap, transitionHook) ->
        trans_map = current_state_transitions()
        for onState, toState of stateTransitionMap
            trans_map[onState] = create_state_trans_def onState, toState, undefined, undefined, transitionHook

    transition_builder = (args...) ->
        # inside event definition?
        if current_event?
            if typeof args[0] is 'object'
                create_state_transitions args[0], args[1]

    transition_builder.from = (states, options, hook) ->
        # inside event definition?
        if current_event?
            trans_map = current_state_transitions()
            _states = if typeof states is 'string' then [states] else states
            for on_state in _states
                trans_map[on_state] = create_state_trans_def on_state, options.to, options.if, options.unless, hook  # options.action

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
