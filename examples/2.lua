#!/usr/bin/env lua

-- Sort the table 'd' based on the values, and emit the tuples "k=v",
-- semicolon-joined, of the results.

local stu = require 'schwartzianTransformUtils'

local d = { q = 2,
            p = 3,
	    r = 1,
	    s = 4,
	    t = 5
}

print (
   table.concat(  -- take the array of "k=v" strings and join them with ";"

      stu.map(                     -- run a function on the sorted keys to 
	                           --   generate "k=v" strings

	 stu.sort(                                 -- sort the keys by value
	    stu.keys(d),
	    function (a,b) return d[a] < d[b]; end
	 ),

	 function(t,k,r) table.insert(r, k .. "=" .. d[k]); end
      ),

      ";")
)
