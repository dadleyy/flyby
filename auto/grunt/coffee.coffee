path = require "path"
path_config = require "./paths"


module.exports =
  debug:
    options:
      bare: false
    files: [{
      ext: ".js"
      cwd: path_config.src
      src: ["**/*.coffee"]
      dest: path_config.dest
      expand: true
    }]
