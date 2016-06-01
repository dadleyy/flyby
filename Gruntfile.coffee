module.exports = (grunt) ->

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-uglify"

  grunt.initConfig
    clean: require "./auto/grunt/clean"
    coffee: require "./auto/grunt/coffee"
    watch: require "./auto/grunt/watch"
    uglify: require "./auto/grunt/uglify"

  grunt.registerTask "clean:all", [
    "clean:cov"
    "clean:dist"
    "clean:temp"
  ]

  grunt.registerTask "release", [
    "clean:all"
    "coffee:debug"
    "uglify:release"
  ]

  grunt.registerTask "default", [
    "clean:all"
    "coffee:debug"
  ]
