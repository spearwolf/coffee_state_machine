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


    it "should auto create state definition for initial state from options", ->

        sm = state_machine "state", initial: "idle", ->

        should.exist sm
        sm.is_valid_state("idle").should.be.ok
        sm.is_valid_state("plah").should.be.not.ok


    it "should auto create state definition for initial state set with state.initial()", ->

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



describe "event helper function", ->

    it "should create a function for each event", ->

        sm = state_machine "state", initial: 'idle', (state, event) ->

            event "start"

            event "stop"

        sm.start.should.be.a "function"
        sm.stop.should.be.a "function"


