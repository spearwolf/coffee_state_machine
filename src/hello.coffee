state_machine = require("./coffee_state_machine").state_machine

state_machine "alarm_state", initial: "off", namespace: "alarm", (event, state, transition) ->

    console.log "inside state machine definition"

