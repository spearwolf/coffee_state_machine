# coffee_state_machine [![Build Status](https://secure.travis-ci.org/spearwolf/coffee_state_machine.png "Build Status")](http://travis-ci.org/spearwolf/coffee_state_machine)

a __finite state machine__ made in and for [CoffeeScript](http://coffeescript.org/) (javascript).

_currently there is no separated documentation - but just take a look into [tests/](test/). it is very easy to use._

this libray is licensed under the [MIT license](LICENSE).


#### some brief, high-level features include:

*  defining state machines on any javascript object or class (constructor)

*  state-driven instance behavior (methods and attributes)

*  hierarchical states (states could have parent/child relationships)

*  state (enter, exit) and transitions callbacks

*  flexible and very readable DSL based around _states_, _events_ and _transitions_.
   design original based on [pluginaweek/state_machine](https://github.com/pluginaweek/state_machine), but now it's slightly different ..

*  high code-coverage using the [mocha](http://visionmedia.github.com/mocha/) test framework

*  written in 100% [CoffeeScript](http://coffeescript.org/)
