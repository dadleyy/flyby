path = require "path"

module.exports = (karma) ->

  jasmineAjax = (files) ->
    pattern = path.resolve require.resolve "jasmine-ajax"
    files.unshift {pattern, included: true, served: true, watched: false}

  jasmineAjax.$inject = ["config.files"]

  files = [
    "src/**/*.coffee"
    "test/**/*.js"
  ]

  reporters = ["progress", "coverage"]

  preprocessors =
    "src/**/*.coffee": ["coverage"]

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
    instrumenters:
      ibrik : require "ibrik"
    instrumenter:
      "**/*.coffee": "ibrik"
    reporters: [
      type: "lcov"
    ]

  karma.set config
