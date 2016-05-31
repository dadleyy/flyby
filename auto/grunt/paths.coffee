path = require "path"

config =
  base: path.join __dirname, "..", ".."

config.src = path.join config.base, "src"
config.dest = path.join config.base, "dist"
config.dest_cov = path.join config.base, "dist-cov"
config.test = path.join config.base, "test"

module.exports = config
