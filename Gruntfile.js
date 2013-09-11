module.exports = function(grunt) {

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-mocha-test');
    grunt.loadNpmTasks('grunt-contrib-uglify');

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        coffee: {
            compile: {
                files: {
                    'lib/coffee_state_machine.js': 'src/coffee_state_machine.coffee'
                }
            }
        },

        clean: ["dist/", "lib/*.js"],

        mochaTest: {
            test: {
                options: {
                    reporter: 'spec',
                    require: 'coffee-script'
                },
                src: ['test/**/*.coffee']
            }
        },

        uglify: {
            options: {
                banner: "/*! <%= pkg.name %> <%= grunt.template.today('yyyy-mm-dd') %> */\n/*! created 2012-13 by Wolfger Schramm <wolfger@spearwolf.de> */\n/*! https://github.com/spearwolf/coffee_state_machine */\n"
            },
            dist: {
                files: {
                    'dist/coffee_state_machine.js': ['lib/coffee_state_machine.js']
                }
            }
        }
    });


    grunt.registerTask('test', ['coffee', 'mochaTest']);
    grunt.registerTask('build', ['coffee', 'uglify']);

    grunt.registerTask('default', 'test');
};
