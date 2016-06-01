path = require "path"

base = path.join __dirname, "..", ".."

src  = path.join base, "src"
dest = path.join base, "dist"
cov  = path.join base, "cov"
temp = path.join base, "tmp"
test = path.join base, "test"

module.exports = {src, base, dest, cov, temp, test}
