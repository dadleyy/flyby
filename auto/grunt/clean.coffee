path = require "path"
path_config = require "./paths"

module.exports =
  dist: path_config.dest
  cov: path_config.cov
  temp: path_config.temp
