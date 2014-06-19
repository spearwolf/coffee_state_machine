# =========================================================
# coffee_state_machine.coffee
# created 2012-14 by Wolfger Schramm <wolfger@spearwolf.de>
# =========================================================

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


    # ========================================
    # STATE helper function
    # ========================================

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
        (state..., fn) ->
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

    obj.is_state = (state) ->
        cur_state = obj[stateAttrName]
        cur_state is state or get_parent_states(cur_state).indexOf(state) >= 0

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


    # ========================================
    # TRANSITION helper function
    # ========================================

    append_common_state_trans_options = (trans_def, ifCallback, unlessCallback, doAction) ->
        trans_def.if = ifCallback if typeof ifCallback is 'function'
        trans_def.unless = unlessCallback if typeof unlessCallback is 'function'
        trans_def.action = doAction if typeof doAction is 'function'
        return trans_def

    create_state_trans_def = (onState, toState, ifCallback, unlessCallback, doAction) ->
        trans_def =
            from: onState
            to: toState
        append_common_state_trans_options trans_def, ifCallback, unlessCallback, doAction

    make_array = (x) ->
        if x?
            if typeof x is 'string'
                [x]
            else
                x
        else
            []

    create_all_state_trans_def = (toState, exceptState, onlyState, ifCallback, unlessCallback, doAction) ->
        trans_def =
            to: toState
            except: make_array(exceptState)
            only: make_array(onlyState)
            is_valid: (state) ->
                if state?
                    (not @toState or @toState is state) and
                        (@except.length is 0 or @except.indexOf(state) < 0) and
                        (@only.length is 0 or @only.indexOf(state) >= 0)
        append_common_state_trans_options trans_def, ifCallback, unlessCallback, doAction

    current_state_transitions = -> obj[current_event].transitions or= {}
    current_all_state_transitions = -> obj[current_event].all_transitions or= []

    create_state_transitions = (stateTransitionMap, transitionHook) ->
        trans_map = current_state_transitions()
        for onState, toState of stateTransitionMap
            trans_map[onState] = create_state_trans_def(
                onState,
                toState,
                undefined,
                undefined,
                transitionHook)

    transition_builder = (args...) ->
        # inside event definition?
        if current_event?
            if typeof args[0] is 'object'
                create_state_transitions args[0], args[1]

    transition_builder.from = (states, options, hook) ->
        if current_event?
            trans_map = current_state_transitions()
            _states = if typeof states is 'string' then [states] else states
            for on_state in _states
                trans_map[on_state] = create_state_trans_def(
                    on_state,
                    options.to,
                    options.if,
                    options.unless,
                    (hook or options.action))

    transition_builder.all = (options= {}, hook= undefined) ->
        if current_event?
            trans_alls = current_all_state_transitions()
            trans_alls.push create_all_state_trans_def(
                options.to,
                options.except,
                options.only,
                options.if,
                options.unless,
                (hook or options.action))

    transition_builder.type = 'coffee_state_machine.TransitionHelperFunction'


    # ========================================
    # EVENT helper function
    # ========================================

    lazy_transition_funcs = []

    current_event = null

    check_transition_callbacks = (trans) ->
        (not trans.if? or trans.if.call(obj)) and (not trans.unless? or not trans.unless.call(obj))

    event_builder = (event, callback) ->

        event_fn = obj[event] or= (props) ->

            current_state = obj[stateAttrName]

            trans = (event_fn.transitions or= {})[current_state]
            trans = null if trans? and not check_transition_callbacks(trans)

            unless trans?
                for all_trans in (event_fn.all_transitions or= [])
                    if all_trans.is_valid(current_state)
                        if check_transition_callbacks(all_trans)
                            trans = all_trans
                            break
            if trans?
                old_state = current_state

                if 'object' is typeof props
                    obj[key] = value for key, value of props

                set_new_state(trans.to)

                current_state = obj[stateAttrName]
                trans_hooks = []

                # collect transition hooks from parents
                for par_state in get_parent_states(old_state)
                    par_trans = event_fn.transitions[par_state]
                    if par_trans? and par_trans.action?
                        if par_trans.to is current_state or get_parent_states(current_state).indexOf(par_trans.to) isnt -1
                            trans_hooks.push(par_trans.action)

                # transition hook
                trans_hooks.push(trans.action) if trans.action?

                # call transition hooks
                trans_hooks_called = []
                for hook in trans_hooks when trans_hooks_called.indexOf(hook) is -1
                    hook.apply obj, [old_state, current_state]
                    trans_hooks_called.push(hook)

                return true

            return false  # no transition found

        if typeof callback is 'function'
            current_event = event
            callback.call obj
            current_event = null

        lazy_transition_builder =
            transition: (args...) ->
                lazy_transition_funcs.push fn: transition_builder, event: event, args: args
                return lazy_transition_builder

        lazy_transition_builder.transition.from = (args...) ->
            lazy_transition_funcs.push fn: transition_builder.from, event: event, args: args
            return lazy_transition_builder

        lazy_transition_builder.transition.all = (args...) ->
            lazy_transition_funcs.push fn: transition_builder.all, event: event, args: args
            return lazy_transition_builder

        return lazy_transition_builder


    event_builder.type = 'coffee_state_machine.EventHelperFunction'


    # ========================================
    # initialize
    # ========================================

    # call given function within context of state object
    fn.call obj, state_builder, event_builder, transition_builder

    # call lazy transition definitions
    for lazy in lazy_transition_funcs
        current_event = lazy.event
        lazy.fn.apply @, lazy.args
    current_event = null

    # add state attribute to object
    obj[stateAttrName] or= options.initial

    # auto create state definition for initial state
    state_builder obj[stateAttrName]

    #obj.all_states = -> all_states
    set_new_state obj[stateAttrName], false

    return obj


# ===== CommonJS and AMD support ====== {{{
if typeof define is 'function' and define.amd
    define -> state_machine
else
    root = exports ? this
    root.state_machine = state_machine
# ====== }}}
