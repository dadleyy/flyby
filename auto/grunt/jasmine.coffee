path = require "path"
path_config = require "./paths"

module.exports = {
  release:
    src: path.join path_config.dest, "**/*.js"
    options:
      display: "full"
      specs: path.join path_config.test, "**/*.spec.js"
      vendor: [
        path.join path_config.base, "node_modules/jasmine-ajax/lib/mock-ajax.js"
      ]
  unit:
    src: path.join path_config.dest, "**/*.js"
    options:
      display: "short"
      specs: path.join path_config.test, "**/*.spec.js"
      vendor: [
        path.join path_config.base, "node_modules/jasmine-ajax/lib/mock-ajax.js"
      ]
}
