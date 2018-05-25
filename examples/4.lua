#!/usr/bin/env lua

-- Standard Decorate-Sort-Undecorate pattern from the first documented
-- case of the Schwartzian Transformation: sort a list of strings by
-- the last word in each string.
--
-- In this case: sort these strings by "Ng", "Kwong", "Gobieramanan",
-- "Nangalama" and emit the entirety of the original string in that
-- sorted order.

local stu = require 'schwartzianTransformUtils'

local d = { 'adjn:Joshua Ng',
	    'adktk:KaLap Timothy Kwong',
	    'admg:Mahalingam Gobieramanan',
	    'admln:Martha L. Nangalama'
	 }

for _,v in ipairs(
	  stu.map(
	     stu.sort(
		stu.map(d, 
			function(t,k,r) table.insert(r, { k, string.gmatch(k, " ([^ ]*)$")() }); end),
		function(a,b) return a[2] < b[2]; end
	     ),
	     function(t,k,r) table.insert(r, k[1]); end)
       ) do
   print (v)
end

