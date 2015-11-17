module.exports = (grunt) ->

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-uglify"

  grunt.initConfig
    clean: require "./auto/grunt/clean"
    jasmine: require "./auto/grunt/jasmine"
    coffee: require "./auto/grunt/coffee"
    watch: require "./auto/grunt/watch"
    uglify: require "./auto/grunt/uglify"

  grunt.registerTask "release", [
    "clean"
    "coffee:debug"
    "jasmine:release"
    "uglify:release"
  ]

  grunt.registerTask "default", [
    "clean"
    "coffee:debug"
    "jasmine:unit"
  ]
