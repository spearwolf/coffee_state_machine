{exec} = require "child_process"

REPORTER = "spec"  #"nyan"

task "build", "build sources", ->
    exec "./node_modules/.bin/coffee -o lib/ -c src/coffee_state_machine.coffee", (err, output) ->
        throw err if err
        console.log output

task "test", "run tests", ->
    invoke 'build'
    exec "NODE_ENV=test
        ./node_modules/.bin/mocha
        --compilers coffee:coffee-script
        --reporter #{REPORTER}
        --require coffee-script
        --colors
        ", (err, output) ->
            throw err if err
            console.log output

