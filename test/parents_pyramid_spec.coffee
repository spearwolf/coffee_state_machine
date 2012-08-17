should = require 'should'
state_machine = require("./../lib/coffee_state_machine").state_machine

describe "hierarchical parents pyramid example", ->

    sm = state_machine "state", initial: "ZERO", (state, event, transition) ->

        state "A", parent: "PAPB", -> 
            foo: 1

        state "B", parent: "PAPB"

        state "C", parent: "PC"

        state "D", parent: "PD"

        state "E", parent: "PE"

        state "F"

        state "PAPB", parent: "PPABC", ->
            foo: 2

        state "PC", parent: "PPABC"

        state "PE", parent: "PPE"

        state "PPABC", ->
            foo: 3

        state "ZERO", ->
            foo: 0


        event "start", -> transition ZERO: "A"

        event "go", -> transition A: "B", B: "C", C: "D", D: "E", E: "F", F: "A"


    it "should correctly initialize", ->

        sm.state.should.be.equal "ZERO"


    it "should know about all possible states", ->

        sm.is_valid_state("ZERO").should.be.ok
        sm.is_valid_state("A").should.be.ok
        sm.is_valid_state("B").should.be.ok
        sm.is_valid_state("C").should.be.ok
        sm.is_valid_state("D").should.be.ok
        sm.is_valid_state("E").should.be.ok
        sm.is_valid_state("F").should.be.ok
        sm.is_valid_state("PAPB").should.be.ok
        sm.is_valid_state("PC").should.be.ok
        sm.is_valid_state("PD").should.be.ok
        sm.is_valid_state("PE").should.be.ok
        sm.is_valid_state("PPABC").should.be.ok
        sm.is_valid_state("PPE").should.be.ok

    #console.log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    #console.log "parents of A -->", sm.get_parent_states("A")
    #console.log "parents of B -->", sm.get_parent_states("B")
    #console.log "parents of C -->", sm.get_parent_states("C")
    #console.log "parents of D -->", sm.get_parent_states("D")
    #console.log "parents of E -->", sm.get_parent_states("E")
    #console.log "parents of F -->", sm.get_parent_states("F")
    #console.log "parents of PAPB -->", sm.get_parent_states("PAPB")
    #console.log "parents of PC -->", sm.get_parent_states("PC")
    #console.log "parents of PPABC -->", sm.get_parent_states("PPABC")
    #console.log "parents of PE -->", sm.get_parent_states("PE")
    #console.log "parents of PPE -->", sm.get_parent_states("PPE")
    #console.log "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

    it "ZERO should has no parents", ->
        sm.get_parent_states("ZERO").should.eql []

    it "A should has PPABC and PAPB as parents", ->
        sm.get_parent_states("A").should.eql ['PPABC', 'PAPB']

    it "B should has PPABC and PAPB as parents", ->
        sm.get_parent_states("B").should.eql ['PPABC', 'PAPB']

    it "C should has PPABC and PC as parents", ->
        sm.get_parent_states("C").should.eql ['PPABC', 'PC']

    it "D should has PD as parent", ->
        sm.get_parent_states("D").should.eql ['PD']

    it "E should has PPE and PE as parents", ->
        sm.get_parent_states("E").should.eql ['PPE', 'PE']

    it "F should has no parents", ->
        sm.get_parent_states("F").should.eql []

    it "PAPB should has PPABC as parent", ->
        sm.get_parent_states("PAPB").should.eql ['PPABC']

    it "PC should has PPABC as parent", ->
        sm.get_parent_states("PC").should.eql ['PPABC']

    it "PD should has no parents", ->
        sm.get_parent_states("PD").should.eql []

    it "PE should has PPE as parent", ->
        sm.get_parent_states("PE").should.eql ['PPE']

    it "PPABC should has no parents", ->
        sm.get_parent_states("PPABC").should.eql []

    it "PPE should has no parents", ->
        sm.get_parent_states("PPE").should.eql []


    it "properties from parents should be overwritten by properties from childs", ->

        sm.foo.should.be.equal 0

        sm.start()
        sm.state.should.be.equal "A"

        sm.foo.should.be.equal 1

        # TODO work in progress


