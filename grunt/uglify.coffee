path = require "path"
path_config = require "./paths"

module.exports =
  release:
    files: [{
      cwd: path_config.dest
      src: ["**/*.js"]
      dest: path_config.dest
      expand: true
      ext: ".min.js"
    }]

