should = require 'should'
state_machine = require("./../lib/coffee_state_machine").state_machine

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
        sm.start.transitions.idle.on.should.be.equal 'idle'
        sm.start.transitions.idle.to.should.be.equal 'running'
        should.not.exist sm.start.transitions.running

        sm.stop.should.be.a 'function'
        sm.stop.transitions.should.be.a 'object'
        sm.stop.transitions.running.should.be.a 'object'
        sm.stop.transitions.running.on.should.be.equal 'running'
        sm.stop.transitions.running.to.should.be.equal 'idle'
        should.not.exist sm.stop.transitions.idle


    it "should create conditional state transition definition if defined by transition.on()", ->

        freezed = no
        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.on "idle", to: "walking", if: -> not freezed

            event "gogogo", ->
                transition.on "idle", to: "walking"

            event "stop", ->
                transition.on "walking", to: "idle", if: -> not freezed

        sm.go.should.be.a 'function'
        sm.go.transitions.should.be.a 'object'
        sm.go.transitions.idle.should.be.a 'object'
        sm.go.transitions.idle.on.should.be.equal 'idle'
        sm.go.transitions.idle.to.should.be.equal 'walking'
        sm.go.transitions.idle.if.should.be.a 'function'
        should.not.exist sm.go.transitions.walking

        sm.gogogo.should.be.a 'function'
        sm.gogogo.transitions.should.be.a 'object'
        sm.gogogo.transitions.idle.should.be.a 'object'
        sm.gogogo.transitions.idle.on.should.be.equal 'idle'
        sm.gogogo.transitions.idle.to.should.be.equal 'walking'
        should.not.exist sm.gogogo.transitions.idle.if
        should.not.exist sm.gogogo.transitions.walking

        sm.stop.should.be.a 'function'
        sm.stop.transitions.should.be.a 'object'
        sm.stop.transitions.walking.should.be.a 'object'
        sm.stop.transitions.walking.on.should.be.equal 'walking'
        sm.stop.transitions.walking.to.should.be.equal 'idle'
        sm.stop.transitions.walking.if.should.be.a 'function'
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



describe "state transistions", ->

    it "could have an optional if: callback", ->

        sm = state_machine "state", (state, event, transition) ->

            @freezed = no

            state.initial "idle"
            state "walking"

            event "go", ->
                transition.on "idle", to: "walking", if: -> not @freezed

            event "stop", ->
                transition.on "walking", to: "idle", if: -> not @freezed

        sm.state.should.be.equal 'idle'
        sm.go()
        sm.state.should.be.equal 'walking'
        sm.stop()
        sm.state.should.be.equal 'idle'
        sm.freezed = yes
        sm.go()
        sm.state.should.be.equal 'idle'



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

            event "stop", -> transition running: "idle", walking: "idle"


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


    it "should invoke enter callbacks defined by state.enter", ->

        is_walking = no
        is_running = no

        on_enter_running = -> is_running = yes

        sm = state_machine "state", (state, event, transition) ->

            state.initial "idle"
            state "running"
            state "walking"

            state.enter "walking", -> is_walking = yes
            state.enter "running", do: on_enter_running

            event "go", -> transition idle: "walking", walking: "running"

            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        is_walking.should.be.not.ok
        is_running.should.be.not.ok
        sm.go()
        sm.state.should.be.equal 'walking'
        is_walking.should.be.ok
        is_running.should.be.not.ok
        sm.go()
        sm.state.should.be.equal 'running'
        is_running.should.be.ok


    it "should invoke exit callbacks defined by state.exit", ->

        is_walking = no
        on_exit_walking = -> is_walking = no

        sm = state_machine "state", (state, event, transition) ->

            state.enter "walking", -> is_walking = yes
            state.exit "walking", do: on_exit_walking

            state.initial "idle"
            state "running"
            state "walking"

            event "go", -> transition idle: "walking", walking: "running"
            event "stop", -> transition running: "idle", walking: "idle"


        sm.state.should.be.equal 'idle'
        is_walking.should.be.not.ok
        sm.go()
        sm.state.should.be.equal 'walking'
        is_walking.should.be.ok
        sm.go()
        sm.state.should.be.equal 'running'
        is_walking.should.be.not.ok

