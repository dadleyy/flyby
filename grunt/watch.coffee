path = require "path"
path_config = require "./paths"

module.exports =  {
  scripts:
    options:
      cwd: path_config.src
    files: ["**/*.coffee"]
    tasks: ["coffee:debug", "jasmine:unit"]
  tests:
    options:
      cwd: path_config.test
    files: ["**/*.js"]
    tasks: ["jasmine:unit"]
}

