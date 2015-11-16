module.exports = (grunt) ->

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-uglify"

  grunt.initConfig
    clean: require "./grunt/clean"
    jasmine: require "./grunt/jasmine"
    coffee: require "./grunt/coffee"
    watch: require "./grunt/watch"
    uglify: require "./grunt/uglify"

  grunt.registerTask "release", [
    "clean"
    "coffee:debug"
    "jasmine:unit"
    "uglify:release"
  ]

  grunt.registerTask "default", [
    "clean"
    "coffee:debug"
    "jasmine:unit"
  ]
