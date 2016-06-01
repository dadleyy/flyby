path = require "path"

module.exports = (karma) ->

  jasmineAjax = (files) ->
    pattern = path.resolve require.resolve "jasmine-ajax"
    files.unshift {pattern, included: true, served: true, watched: false}

  jasmineAjax.$inject = ["config.files"]

  files = [
    "dist/flyby.js"
    "test/**/*.js"
  ]

  reporters = ["progress", "coverage"]

  preprocessors =
    "dist/flyby.js": ["coverage"]

  browsers = ["PhantomJS"]

  plugins = [
    "karma-jasmine"
    "karma-coverage"
    "karma-coffee-preprocessor"
    "karma-phantomjs-launcher"
    {"framework:jasmine-ajax": ["factory", jasmineAjax]}
  ]

  frameworks = [
    "jasmine-ajax"
    "jasmine"
  ]

  config = {files, reporters, browsers, plugins, frameworks, preprocessors}

  config.coffeePreprocessor =
    options: sourceMaps: true

  config.coverageReporter =
    dir: "./cov"
    reporters: [{
      type: "json"
      subdir: "."
    }]

  karma.set config
