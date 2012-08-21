should = require "should"
{state_machine} = require "./../lib/coffee_state_machine"

describe "hierarchical parents pyramid example", ->

    flags = 
        papb:
            enter: false, exit: false
        pc:
            enter: false, exit: false
        pd:
            enter: false, exit: false
        pe:
            enter: false, exit: false
        ppabc:
            enter: false, exit: false
        ppe:
            enter: false, exit: false

    switch_on = (state, hook) ->
        -> flags[state][hook] = true

    switch_all_off = ->
        for state, flag of flags
            [flag.enter, flag.exit] = [false, false]


    sm = state_machine "state", initial: "ZERO", (state, event, transition) ->

        state "A", parent: "PAPB", -> 
            foo: 1

        state "B", parent: "PAPB"

        state "C", parent: "PC"

        state "D", parent: "PD"

        state "E", parent: "PE"

        state "F"

        state "PAPB", parent: "PPABC", enter: switch_on("papb", "enter"), exit: switch_on("papb", "exit"), ->
            foo: 2

        state "PC", parent: "PPABC", enter: switch_on("pc", "enter"), exit: switch_on("pc", "exit")

        state "PD", enter: switch_on("pd", "enter"), exit: switch_on("pd", "exit")

        state "PE", parent: "PPE", enter: switch_on("pe", "enter"), exit: switch_on("pe", "exit")

        state "PPE", enter: switch_on("ppe", "enter"), exit: switch_on("ppe", "exit")

        state "PPABC", enter: switch_on("ppabc", "enter"), exit: switch_on("ppabc", "exit"), ->
            foo: 3

        state "ZERO", ->
            foo: 0


        event "start", -> transition ZERO: "A", B: "A", C: "A", D: "A", E: "A", F: "A"

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

    it "at ZERO stage foo should be 0", ->
        sm.foo.should.be.equal 0

    it "ZERO -> A", ->
        sm.start()
        sm.state.should.be.equal "A"
        sm.foo.should.be.equal 1

    it "A -> B", ->
        sm.start()
        sm.state.should.be.equal "A"

        switch_all_off()
        sm.go()
        sm.state.should.be.equal "B"

    it "A -> B foo should be correct", -> sm.foo.should.be.equal 2
    it "A -> B PAPB:enter should be NOT called", -> flags.papb.enter.should.be.equal false
    it "A -> B PAPB:exit should be NOT called", -> flags.papb.exit.should.be.equal false
    it "A -> B PC:enter should be NOT called", -> flags.pc.enter.should.be.equal false
    it "A -> B PC:exit should be NOT called", -> flags.pc.exit.should.be.equal false
    it "A -> B PD:enter should be NOT called", -> flags.pd.enter.should.be.equal false
    it "A -> B PD:exit should be NOT called", -> flags.pd.exit.should.be.equal false
    it "A -> B PE:enter should be NOT called", -> flags.pe.enter.should.be.equal false
    it "A -> B PE:exit should be NOT called", -> flags.pe.exit.should.be.equal false
    it "A -> B PPABC:enter should be NOT called", -> flags.ppabc.enter.should.be.equal false
    it "A -> B PPABC:exit should be NOT called", -> flags.ppabc.exit.should.be.equal false
    it "A -> B PPE:enter should be NOT called", -> flags.ppe.enter.should.be.equal false
    it "A -> B PPE:exit should be NOT called", -> flags.ppe.exit.should.be.equal false

    it "B -> C", ->
        switch_all_off()
        sm.go()
        sm.state.should.be.equal "C"

    it "B -> C foo should be correct", -> sm.foo.should.be.equal 3
    it "B -> C PAPB:enter should be NOT called", -> flags.papb.enter.should.be.equal false
    it "B -> C PAPB:exit should be called", -> flags.papb.exit.should.be.equal true
    it "B -> C PC:enter should be called", -> flags.pc.enter.should.be.equal true
    it "B -> C PC:exit should be NOT called", -> flags.pc.exit.should.be.equal false
    it "B -> C PD:enter should be NOT called", -> flags.pd.enter.should.be.equal false
    it "B -> C PD:exit should be NOT called", -> flags.pd.exit.should.be.equal false
    it "B -> C PE:enter should be NOT called", -> flags.pe.enter.should.be.equal false
    it "B -> C PE:exit should be NOT called", -> flags.pe.exit.should.be.equal false
    it "B -> C PPABC:enter should be NOT called", -> flags.ppabc.enter.should.be.equal false
    it "B -> C PPABC:exit should be NOT called", -> flags.ppabc.exit.should.be.equal false
    it "B -> C PPE:enter should be NOT called", -> flags.ppe.enter.should.be.equal false
    it "B -> C PPE:exit should be NOT called", -> flags.ppe.exit.should.be.equal false

    it "C -> D", ->
        switch_all_off()
        sm.go()
        sm.state.should.be.equal "D"

    it "C -> D foo should be correct", -> should.not.exist sm.foo
    it "C -> D PAPB:enter should be NOT called", -> flags.papb.enter.should.be.equal false
    it "C -> D PAPB:exit should be NOT called", -> flags.papb.exit.should.be.equal false
    it "C -> D PC:enter should be NOT called", -> flags.pc.enter.should.be.equal false
    it "C -> D PC:exit should be called", -> flags.pc.exit.should.be.equal true
    it "C -> D PD:enter should be called", -> flags.pd.enter.should.be.equal true
    it "C -> D PD:exit should be NOT called", -> flags.pd.exit.should.be.equal false
    it "C -> D PE:enter should be NOT called", -> flags.pe.enter.should.be.equal false
    it "C -> D PE:exit should be NOT called", -> flags.pe.exit.should.be.equal false
    it "C -> D PPABC:enter should be NOT called", -> flags.ppabc.enter.should.be.equal false
    it "C -> D PPABC:exit should be called", -> flags.ppabc.exit.should.be.equal true
    it "C -> D PPE:enter should be NOT called", -> flags.ppe.enter.should.be.equal false
    it "C -> D PPE:exit should be NOT called", -> flags.ppe.exit.should.be.equal false

    it "D -> E", ->
        switch_all_off()
        sm.go()
        sm.state.should.be.equal "E"

    it "D -> E foo should be correct", -> should.not.exist sm.foo
    it "D -> E PAPB:enter should be NOT called", -> flags.papb.enter.should.be.equal false
    it "D -> E PAPB:exit should be NOT called", -> flags.papb.exit.should.be.equal false
    it "D -> E PC:enter should be NOT called", -> flags.pc.enter.should.be.equal false
    it "D -> E PC:exit should be NOT called", -> flags.pc.exit.should.be.equal false
    it "D -> E PD:enter should be NOT called", -> flags.pd.enter.should.be.equal false
    it "D -> E PD:exit should be called", -> flags.pd.exit.should.be.equal true
    it "D -> E PE:enter should be called", -> flags.pe.enter.should.be.equal true
    it "D -> E PE:exit should be NOT called", -> flags.pe.exit.should.be.equal false
    it "D -> E PPABC:enter should be NOT called", -> flags.ppabc.enter.should.be.equal false
    it "D -> E PPABC:exit should be NOT called", -> flags.ppabc.exit.should.be.equal false
    it "D -> E PPE:enter should be called", -> flags.ppe.enter.should.be.equal true
    it "D -> E PPE:exit should be NOT called", -> flags.ppe.exit.should.be.equal false

    it "E -> F", ->
        switch_all_off()
        sm.go()
        sm.state.should.be.equal "F"

    it "E -> F foo should be correct", -> should.not.exist sm.foo
    it "E -> F PAPB:enter should be NOT called", -> flags.papb.enter.should.be.equal false
    it "E -> F PAPB:exit should be NOT called", -> flags.papb.exit.should.be.equal false
    it "E -> F PC:enter should be NOT called", -> flags.pc.enter.should.be.equal false
    it "E -> F PC:exit should be NOT called", -> flags.pc.exit.should.be.equal false
    it "E -> F PD:enter should be NOT called", -> flags.pd.enter.should.be.equal false
    it "E -> F PD:exit should be NOT called", -> flags.pd.exit.should.be.equal false
    it "E -> F PE:enter should be NOT called", -> flags.pe.enter.should.be.equal false
    it "E -> F PE:exit should be called", -> flags.pe.exit.should.be.equal true
    it "E -> F PPABC:enter should be NOT called", -> flags.ppabc.enter.should.be.equal false
    it "E -> F PPABC:exit should be NOT called", -> flags.ppabc.exit.should.be.equal false
    it "E -> F PPE:enter should be NOT called", -> flags.ppe.enter.should.be.equal false
    it "E -> F PPE:exit should be called", -> flags.ppe.exit.should.be.equal true

    it "F -> A", ->
        switch_all_off()
        sm.go()
        sm.state.should.be.equal "A"

    it "F -> A foo should be correct", -> sm.foo.should.be.equal 1
    it "F -> A PAPB:enter should be called", -> flags.papb.enter.should.be.equal true
    it "F -> A PAPB:exit should be NOT called", -> flags.papb.exit.should.be.equal false
    it "F -> A PC:enter should be NOT called", -> flags.pc.enter.should.be.equal false
    it "F -> A PC:exit should be NOT called", -> flags.pc.exit.should.be.equal false
    it "F -> A PD:enter should be NOT called", -> flags.pd.enter.should.be.equal false
    it "F -> A PD:exit should be NOT called", -> flags.pd.exit.should.be.equal false
    it "F -> A PE:enter should be NOT called", -> flags.pe.enter.should.be.equal false
    it "F -> A PE:exit should be NOT called", -> flags.pe.exit.should.be.equal false
    it "F -> A PPABC:enter should be called", -> flags.ppabc.enter.should.be.equal true
    it "F -> A PPABC:exit should be NOT called", -> flags.ppabc.exit.should.be.equal false
    it "F -> A PPE:enter should be NOT called", -> flags.ppe.enter.should.be.equal false
    it "F -> A PPE:exit should be NOT called", -> flags.ppe.exit.should.be.equal false



