should = require "should"
{state_machine} = require "./../lib/coffee_state_machine"

describe "transtion.all", ->

    it "to: <state> should have lower prio than concrete to-transition def", ->

        sm = state_machine 'state', (state, event, transition) ->

            @all_active = no
            @is_concrete_to_transition = no
            @hola = false

            state.initial 'foo'
            state 'bar'
            state 'plah'

            event 'yep', ->

                transition
                    bar: 'plah'
                    plah: 'foo'

                transition.from 'foo', to: 'bar', unless: (-> @all_active), ->
                    @is_concrete_to_transition = yes

                transition.all to: 'bar', ->
                    @is_concrete_to_transition = no

                #transition.all -> @hola = yes


            event 'urks', ->
                transition.all to: 'foo'


        sm.is_state('foo').should.be.ok
        sm.hola.should.be.not.ok

        sm.yep()
        sm.state.should.be.equal 'bar'
        sm.is_concrete_to_transition.should.be.ok

        sm.yep()
        sm.state.should.be.equal 'plah'

        sm.urks()
        sm.state.should.be.equal 'foo'

        sm.all_active = yes
        sm.is_concrete_to_transition.should.be.ok
        sm.hola = no

        sm.yep()
        sm.state.should.be.equal 'bar'
        sm.is_concrete_to_transition.should.be.not.ok
        #sm.hola.should.be.ok


