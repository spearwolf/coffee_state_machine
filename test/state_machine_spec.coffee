should = require 'should'
state_machine = require("./../lib/coffee_state_machine").state_machine

describe "state_machine", ->

    it "should return an object", ->

        sm = state_machine "state", initial: "idle", -> false

        should.exist sm
        sm.should.be.a "object"


    it "should return an object with initialized state attribute", ->

        sm = state_machine "state", initial: "idle", -> false

        sm.state.should.be.equal "idle"


    it "should return and use object from 'extend' option", ->

        foo =
            bar: 23

        sm = state_machine "state", initial: "idleidle", extend: foo, -> false

        sm.should.be.equal foo
        sm.bar.should.be.equal 23
        sm.state.should.be.equal "idleidle"


    it "should return new object created by 'class' option constructor", ->

        class Foo
            constructor: -> @bar = 42

        sm = state_machine "state", initial: "foobar", class: Foo, -> false

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


