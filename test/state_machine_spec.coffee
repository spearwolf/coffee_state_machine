should = require "should"
{state_machine} = require "./../lib/coffee_state_machine"

describe "state_machine", ->

    it "should return an object", ->

        sm = state_machine "state", initial: "idle", ->

        should.exist sm
        sm.should.be.a "object"


    it "should return an object with initialized state attribute", ->

        sm = state_machine "state", initial: "idle", ->

        sm.state.should.be.equal "idle"


    it "should return and use object from 'extend' option", ->

        foo =
            bar: 23

        sm = state_machine "state", initial: "idleidle", extend: foo, ->

        sm.should.be.equal foo
        sm.bar.should.be.equal 23
        sm.state.should.be.equal "idleidle"


    it "should return new object created by 'class' option constructor", ->

        class Foo
            constructor: -> @bar = 42

        sm = state_machine "state", initial: "foobar", class: Foo, ->

        sm.bar.should.be.equal 42
        sm.state.should.be.equal "foobar"


    it "should call given callback function within context of state object", ->

        plah =
            foo: 111

        self = null

        sm = state_machine "state", initial: "idle", extend: plah, ->
            self = @
            @gulp = 23

        sm.should.be.equal self
        sm.gulp.should.be.equal 23
        sm.gulp.should.be.equal self.gulp


    it "should call given callback function with state helper function as first parameter", ->

        state_func = undefined

        state_machine "state", (state) -> state_func = state

        should.exist state_func
        state_func.should.be.a "function"
        state_func.type.should.be.equal 'coffee_state_machine.StateHelperFunction'


    it "should call given callback function with event helper function as second parameter", ->

        event_func = undefined

        state_machine "state", (state, event) -> event_func = event

        should.exist event_func
        event_func.should.be.a "function"
        event_func.type.should.be.equal 'coffee_state_machine.EventHelperFunction'


    it "should call given callback function with transition helper function as third parameter", ->

        transition_func = undefined

        state_machine "state", (state, event, transition) -> transition_func = transition

        should.exist transition_func
        transition_func.should.be.a "function"
        transition_func.type.should.be.equal 'coffee_state_machine.TransitionHelperFunction'


    it "should implicit register state for initial state defined by option 'initial'", ->

        sm = state_machine "state", initial: "idle", ->

        should.exist sm
        sm.is_valid_state("idle").should.be.ok
        sm.is_valid_state("plah").should.be.not.ok


    it "should implicit register state for initial state defined by state.initial()", ->

        sm = state_machine "state", (state) -> state.initial "plah"

        should.exist sm
        sm.is_valid_state("plah").should.be.ok
        sm.is_valid_state("idle").should.be.not.ok



describe "state helper function", ->

    it "should have .initial() method to set initial state", ->

        state_func1 = undefined

        sm = state_machine "state", (state) ->

            state.initial "foo"

            state_func1 = state

        should.exist state_func1
        state_func1.should.be.a "function"
        state_func1.initial.should.be.a "function"
        sm.state.should.be.equal "foo"


    it "should register a new state if called", ->

        sm = state_machine "state", initial: 'idle', (state) ->

            state "running"

            state "waiting"


        sm.is_valid_state("running").should.be.ok
        sm.is_valid_state("waiting").should.be.ok
        sm.is_valid_state("foobar").should.be.not.ok


    it "should implicit register parent state if called with option 'parent'", ->

        sm = state_machine "state", initial: 'idle', (state) ->

            state "running", parent: 'motion'

            state "idle", parent: 'downtime'

        sm.is_valid_state("running").should.be.ok
        sm.is_valid_state("idle").should.be.ok
        sm.is_valid_state("motion").should.be.ok
        sm.is_valid_state("downtime").should.be.ok



describe "event helper function", ->

    it "should create a function for each event", ->

        sm = state_machine "state", initial: 'idle', (state, event) ->

            event "start"

            event "stop"

        sm.start.should.be.a "function"
        sm.stop.should.be.a "function"



describe "transition helper function", ->

    it "should create state transition definition for each key if called with an object as only argument", ->

        sm = state_machine "state", initial: 'idle', (state, event, transition) ->

            state "running"

            event "start", -> transition idle: "running"

            event "stop", -> transition running: "idle"

        sm.start.should.be.a 'function'
        sm.start.transitions.should.be.a 'object'
        sm.start.transitions.idle.should.be.a 'object'
        sm.start.transitions.idle.from.should.be.equal 'idle'
        sm.start.transitions.idle.to.should.be.equal 'running'
        should.not.exist sm.start.transitions.running

        sm.stop.should.be.a 'function'
        sm.stop.transitions.should.be.a 'object'
        sm.stop.transitions.running.should.be.a 'object'
        sm.stop.transitions.running.from.should.be.equal 'running'
        sm.stop.transitions.running.to.should.be.equal 'idle'
        should.not.exist sm.stop.transitions.idle


    it "should create conditional state transition definition if defined by transition.from()", ->

        freezed = no
        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.from "idle", to: "walking", if: -> not freezed

            event "gogogo", ->
                transition.from "idle", to: "walking"

            event "stop", ->
                transition.from "walking", to: "idle", unless: -> freezed

        sm.go.should.be.a 'function'
        sm.go.transitions.should.be.a 'object'
        sm.go.transitions.idle.should.be.a 'object'
        sm.go.transitions.idle.from.should.be.equal 'idle'
        sm.go.transitions.idle.to.should.be.equal 'walking'
        sm.go.transitions.idle.if.should.be.a 'function'
        should.not.exist sm.go.transitions.walking

        sm.gogogo.should.be.a 'function'
        sm.gogogo.transitions.should.be.a 'object'
        sm.gogogo.transitions.idle.should.be.a 'object'
        sm.gogogo.transitions.idle.from.should.be.equal 'idle'
        sm.gogogo.transitions.idle.to.should.be.equal 'walking'
        should.not.exist sm.gogogo.transitions.idle.if
        should.not.exist sm.gogogo.transitions.walking

        sm.stop.should.be.a 'function'
        sm.stop.transitions.should.be.a 'object'
        sm.stop.transitions.walking.should.be.a 'object'
        sm.stop.transitions.walking.from.should.be.equal 'walking'
        sm.stop.transitions.walking.to.should.be.equal 'idle'
        sm.stop.transitions.walking.unless.should.be.a 'function'
        should.not.exist sm.stop.transitions.idle



describe "state_machine event functions", ->

    it "should switch state if called (for state transitions)", ->

        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle"
            state "running"
            state "walking"

            event "go", -> transition idle: "walking", walking: "running"

            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.go()
        sm.state.should.be.equal 'running'
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.stop()
        sm.state.should.be.equal 'idle'


    it "should return true if state changed, otherwise false", ->

        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle"
            state "running"
            state "walking"

            event "go", -> transition idle: "walking"

            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        sm.go().should.be.equal true
        sm.state.should.be.equal 'walking'
        sm.go().should.be.equal false
        sm.state.should.be.equal 'walking'
        sm.stop().should.be.equal true
        sm.state.should.be.equal 'idle'



describe "state transistions", ->

    it "could have an optional if: callback", ->

        sm = state_machine "state", (state, event, transition) ->

            @freezed = no

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.from "idle", to: "walking", if: -> not @freezed

            event "stop", ->
                transition.from "walking", to: "idle", if: -> not @freezed

        sm.state.should.be.equal 'idle'
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.freezed = yes
        sm.go()
        sm.state.should.be.equal 'idle'


    it "could have an optional unless: callback", ->

        sm = state_machine "state", (state, event, transition) ->

            @freezed = no

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.from "idle", to: "walking", unless: -> @freezed

            event "stop", ->
                transition.from "walking", to: "idle", unless: -> @freezed

        sm.state.should.be.equal 'idle'
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.freezed = yes
        sm.go()
        sm.state.should.be.equal 'idle'


    it "could have an optional callback (transition hook)", ->

        sm = state_machine "state", (state, event, transition) ->

            @speed = 0

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.from "idle", to: "walking", -> @speed += 1

            event "stop", ->
                transition.from "walking", to: "idle", -> @speed -= 1

        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.speed.should.be.equal 1
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0


    it "transition hooks should be called with oldState and event args as function arguments", ->

        sm = state_machine "state", (state, event, transition) ->

            @speed = 0

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.from "idle", to: "walking", (oldState, v) ->
                    oldState.should.be.equal 'idle'
                    @speed += v

            event "stop", ->
                transition walking: "idle", (oldState, v) ->
                    oldState.should.be.equal 'walking'
                    @speed -= v

        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.go(7)
        sm.state.should.be.equal 'walking'
        sm.speed.should.be.equal 7
        sm.stop(4)
        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 3


    it "transition hooks should also work for parent states", ->

        sm = state_machine "state", (state, event, transition) ->

            @speed = 0
            @foo = 0
            @bar = 0

            state.initial "idle", parent: "FOO"
            state "walking", parent: "BAR"
            state "BAR", parent: "ROOT"

            event "go", ->
                transition.from "idle", to: "walking", (oldState) ->
                    oldState.should.be.equal 'idle'
                    @speed += 1
                transition.from "FOO", to: "walking", -> @foo += 1

            event "stop", ->
                transition walking: "idle", (oldState) ->
                    oldState.should.be.equal 'walking'
                    @speed -= 1
                transition BAR: "FOO", -> @bar += 2
                transition ROOT: "FOO", -> @bar += 3

        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.foo.should.be.equal 0
        sm.bar.should.be.equal 0
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.speed.should.be.equal 1
        sm.foo.should.be.equal 1
        sm.bar.should.be.equal 0
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.foo.should.be.equal 1
        sm.bar.should.be.equal 5


    it "transition hooks should not be called twice", ->

        sm = state_machine "state", (state, event, transition) ->

            @speed = 0
            @foo = 0
            @bar = 0

            @inc_bar = -> @bar =+ 7

            state.initial "idle", parent: "FOO"
            state "walking", parent: "BAR"
            state "BAR", parent: "ROOT"

            event "go", ->
                transition.from "idle", to: "walking", -> @speed += 1
                transition.from "FOO", to: "walking", -> @foo += 1

            event "stop", ->
                transition walking: "idle", -> @speed -= 1
                transition BAR: "FOO", @inc_bar
                transition ROOT: "FOO", @inc_bar

        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.foo.should.be.equal 0
        sm.bar.should.be.equal 0
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.speed.should.be.equal 1
        sm.foo.should.be.equal 1
        sm.bar.should.be.equal 0
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.foo.should.be.equal 1
        sm.bar.should.be.equal 7



describe "switching states", ->

    it "should set properties and methods from state definition", ->

        sm = state_machine "state", (state, event, transition) ->

            @speed = 0

            state.initial "idle", ->
                getSpeedPlusOne: -> @speed + 1

            state "running", ->
                speed: 10
                getSpeedPlusOne: -> @speed + 4

            state "walking", ->
                speed: 5
                getSpeedPlusOne: -> @speed + 2

            event "go", -> transition idle: "walking", walking: "running"

            event "stop", -> transition.from ["running", "walking"], to: "idle"


        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.getSpeedPlusOne().should.be.equal 1
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.speed.should.be.equal 5
        sm.getSpeedPlusOne().should.be.equal 7
        sm.go()
        sm.state.should.be.equal 'running'
        sm.speed.should.be.equal 10
        sm.getSpeedPlusOne().should.be.equal 14
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.speed.should.be.equal 0
        sm.getSpeedPlusOne().should.be.equal 1


    it "should invoke enter hooks defined by state.enter", ->

        is_walking = no
        is_running = no
        is_initialized_idle = no

        on_enter_running = -> is_running = yes
        on_initial_enter_idle = -> is_initialized_idle = yes


        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle", enter: on_initial_enter_idle
            state "running"
            state "walking"

            state.enter "walking", -> is_walking = yes
            state.enter "running", on_enter_running

            event "go", -> transition idle: "walking", walking: "running"

            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        is_initialized_idle.should.be.ok
        is_walking.should.be.not.ok
        is_running.should.be.not.ok
        sm.go()
        sm.state.should.be.equal 'walking'
        is_walking.should.be.ok
        is_running.should.be.not.ok
        sm.go()
        sm.state.should.be.equal 'running'
        is_running.should.be.ok


    it "should invoke exit hooks defined by state.exit", ->

        is_walking = no

        sm = state_machine "state", (state, event, transition) ->

            @go_count = 0
            @inc_go_count = -> @go_count += 1

            state.enter "walking", -> is_walking = yes
            state.enter "walking", "running", @inc_go_count

            state.initial "idle"
            state "running"
            state "walking", exit: -> is_walking = no if @state is 'walking'

            event "go", -> transition idle: "walking", walking: "running"
            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        is_walking.should.be.not.ok
        sm.go_count.should.be.equal 0
        sm.go()
        sm.state.should.be.equal 'walking'
        is_walking.should.be.ok
        sm.go_count.should.be.equal 1
        sm.go()
        sm.state.should.be.equal 'running'
        is_walking.should.be.not.ok
        sm.go_count.should.be.equal 2


    it "should also invoke enter hooks from parents", ->

        is_walking = no
        on_exit_walking = -> is_walking = no

        sm = state_machine "state", (state, event, transition) ->

            @go_count = 0
            @inc_go_count = -> @go_count += 1

            @motion_count = 0
            @inc_motion_count = -> @motion_count += 2

            @foobar = 7

            state.enter "walking", -> is_walking = yes
            state.enter "walking", "running", @inc_go_count

            state.initial "idle", ->
                foobar: 13

            state "running", parent: "motion", ->
                foobar: 14

            state "walking", parent: "motion", exit: on_exit_walking

            state "motion", enter: @inc_motion_count, ->
                foobar: 23

            event "go", -> transition idle: "walking", walking: "running"
            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        is_walking.should.be.not.ok
        sm.go_count.should.be.equal 0
        sm.motion_count.should.be.equal 0
        sm.foobar.should.be.equal 13
        sm.go()
        sm.state.should.be.equal 'walking'
        is_walking.should.be.ok
        sm.go_count.should.be.equal 1
        sm.motion_count.should.be.equal 2
        sm.foobar.should.be.equal 23
        sm.go()
        sm.state.should.be.equal 'running'
        is_walking.should.be.not.ok
        sm.go_count.should.be.equal 2
        sm.motion_count.should.be.equal 2
        sm.foobar.should.be.equal 14





# TODO
#
# transition.all :except => [], :only => []
# transition.same()



