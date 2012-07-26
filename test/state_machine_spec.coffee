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


