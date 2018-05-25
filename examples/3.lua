#!/usr/bin/env lua

-- Construct a table of [str,len]; then sort on len; then discard len
-- and leave behind the strings. 
--
-- (This is the Wikipedia sample Schwartzian Transformation.)

local stu = require 'schwartzianTransformUtils'

local d = { 'aaaa', 'a', 'aa' }

for _,v in ipairs(
	  stu.map(
	     stu.sort(
		stu.map(d, 
			function(t,k,r) table.insert(r, { k, string.len(k) }); end),
		function(a,b) if (a[2] < b[2]) then return true else return a[1] < b[1]; end; end
	     ),
	     function(t,k,r) table.insert(r, k[1]); end)
       ) do
   print (v)
end
