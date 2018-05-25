#!/usr/bin/env lua

-- Sort the keys of the table 'd' based on the keys' values.

local stu = require 'schwartzianTransformUtils'
local d = { a = 2,
            c = 1,
            t = 3 }
for _,v in ipairs(stu.sort(stu.keys(d),
                           function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end

io.write("\n")
