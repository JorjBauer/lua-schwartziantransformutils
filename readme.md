# Overview

Schwartzian transformations are hard in Lua. This module has some 
functions that make them easier. None of these functions is new or novel.

# Examples

There are four example scripts in the examples/ directory. Two of them
are simple sorts by secondary characteristics, and two of them are the
classic Lisp "Decorate-Sort-Undecorate" pattern that is now often
called a Schwartzian Transformation. (This document focuses on
permutations of the two simple scripts to describe the general problem
with performing this sort of work easily in Lua.)

## Simple secondary sort

```lua
#!/usr/bin/env lua
local stu = require 'schwartzianTransformUtils'
local d = { a = 2,
            c = 1,
            t = 3 }
for _,v in ipairs(stu.sort(stu.keys(d), 
    	   		      function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```
    
output: "*cat*" (keys of the table are sorted by their values)

## Sort with transformation data formatting

```lua
#!/usr/bin/env lua
local stu = require 'schwartzianTransformUtils'
local d = { q = 2,
            p = 3,
            r = 1,
            s = 4,
            t = 5
}
print (
   table.concat( 
      stu.map( 
	 stu.sort(
	    stu.keys(d),
	    function (a,b) return d[a] < d[b]; end
	 ),
	 function(t,k,r) table.insert(r, k .. "=" .. d[k]); end
      ),
      ";")
)
```

output: "*r=1;q=2;p=3;s=4;t=5*" (keys of the table are sorted by their values, and a function is called to generate output from both)

## Schwartzian transformation: sort by string length

```lua
#!/usr/bin/env lua
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
```

Output:

    a
    aa
    aaaa
    
## Schwartzian transformation: sort by last "word" in string

```lua
#!/usr/bin/env lua
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
```

Output:

    admg:Mahalingam Gobieramanan
    adktk:KaLap Timothy Kwong
    admln:Martha L. Nangalama
    adjn:Joshua Ng
 

# Deeper analysis

I'm a Perl fan. It makes a lot of data manipulation fairly easy. Take
this small script which generates the output "cat":

```perl
my $d = { 'a' => 2,
          'c' => 1,
          't' => 3 };
foreach my $i (sort { $d->{$a} cmp $d->{$b} } keys %$d) {
  print $i;
}
```

... by way of *"construct a sorted array of the keys of hash reference
$d, where they are sorted by the value of each hash key; and then
print each of those sorted keys, in order."*

It would be nice to be able to do the same as a Lua one-liner
something like this:

```lua
local d = { a = 2,
            c = 1,
            t = 3 }
for _,v in ipairs(d:keys():sort(function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```

Unfortunately, there are two reasons why we can't do that in stock
Lua. Tables in Lua have no *keys()* method to return keys; and
*table.sort()* doesn't return a copy of the table (it's entirely
sort-in-place).

This means that we need to create a more complex function to perform
those fundamental pieces of work, like so:

```lua
function sortedKeys(t, f)
   local keys = {}
   for key in pairs(t) do
      table.insert(keys, key)
   end

   table.sort(keys, f)

   return keys
end

local d = { a = 2,
                 c = 1,
                 t = 3 }
for _,v in ipairs(sortedKeys(d, function(a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```

... which is functional, but (at least in my eyes) not elegant. The
*sortedKeys()* function, which is both performing the transformation
(pulling out the keys and operating on them) and the sort (which
happens in-place on the local keys array) before returning the
results, needs to be copied project-to-project (a good case for
encapsulating it in a module).

This isn't the direction I'd like to move in, though; I'd rather adopt
the simplicity of chained functional primitives in Lua. If we
monkey-patch the table module, changing its default behavior for
*sort()*...

```lua
local _origSort = table.sort
function table:sort(f)
   _origSort(self,f)
   return self
end

function table:keys()
   local keys = {}
   for key in pairs(self) do
      table.insert(keys, key)
   end
   return keys
end
```

This makes the *table.sort()* function return the table, and adds a new
*keys()* function. It's almost what we originally wanted - except that a
table's not really an object, so the ':' syntactic sugar doesn't work
from the caller. But it's now achievable as a single nested set of
primitives:

```lua
local d = { a = 2,
            c = 1,
            t = 3 }
for _,v in ipairs(table.sort(table.keys(d), 
    	   		     function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```

If we want to get to the full intended syntax to work, then we have to
dig deeper; we need to update the metatable for table 'd' to be a
"table object" so that it knows how to call a method in that object:

```lua
local d = { a = 2,
            c = 1,
            t = 3 }
setmetatable(d, {__index = table})
for _,v in ipairs(table.sort(d:keys(), 
    	   		     function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```

This is close, but the final *:sort()* won't work. *d:keys()* returns
a new table which is not "blessed" as a table object; therefore, you
can't call the *:sort()* method on it. If we want that to work then we
also need to change the *table.keys()* function to return a blessed
object:

```lua
function table:keys()
   local keys = {}
   for key in pairs(self) do
      table.insert(keys, key)
   end
   setmetatable(keys, {__index = table})
   return keys
end
```

At which point we could perform this seeming magic:

```lua
local d = { a = 2,
            c = 1,
            t = 3 }
setmetatable(d,{__index = table})
for _,v in ipairs((d:keys()):sort(function (a,b) return d[a] < d[b]; end)) do
   io.write(v)
end
```

# ... But Monkey Patching is terrible

You might be able to see that this is turtles all the way down: where
do we stop when deciding to patch built-in functionality? This sort of
surgery lacks elegance; we will never contain all of it, and it will
probably have unintended side-effects. What happens, for example, when
we load two third-party modules that both decide to monkey-patch the
same functions with competing functionality?

Given this uncontainable sprawl, reaching for these last few syntactic
sugar improvements are a bad trade-off; sure, you can do it, but you
sacrifice general stability in the process (i.e. it only works in
specific situations that you have deliberately engineered).

This module, therefore, doesn't monkey-patch; it returns a standard
table object, as with most Lua modules. For simplicity in this
discussion, we'll continue to monkey-patch. In the actual working
examples at the top of this document, you'll see that the final
implementation does not.

# Extended usefulness

What about a case where we want to print a delimited list of the
key/value pairs, in value-sorted order?

Well, starting from the beginning again: Perl has a *join()* analogous
to Lua's *table.concat()*. We can get the keys in value-sorted order
like this (assuming we're using the above monkey-patch):

```lua
local d = { q = 2,
            p = 3 }
print (table.concat(table.sort(table.keys(d), 
                               function(a,b) return d[a] < d[b]; end
                               ), 
                    ";")
      )
```

Which emits "**q;p**". If we want to also emit the values
("**q=2;p=3**"), we really need another layer of functionality. While
we could build a local function to specifically build a string of the
key-value pairs in sorted order, that would be a solution to a
specific problem; I'd rather solve the general problem, and build an
extensible pattern. So perhaps what we want is an analog to the Perl
*map()* function.

Looking at the first problem, we could have rewritten it like this
using Perl's *map()*:

```perl
my $d = { 'a' => 2,
          'c' => 1,
          't' => 3 };
map { print $_ } sort { $d->{$a} cmp $d->{$b} } keys %$d;
```

You could read that as "*evaluate the anonymous function '{ print $_ }'
for each element of the sorted list.*"

But if those anonymous functions return values, then Perl's *map()*
also returns the constructed element of all of those function
calls. So we could construct a list using *map()*, and then *join()*
it together:

```perl
my $d = { 'q' => 3,
      	  'p' => 2 };
print 
  join(',', 
       map { $_ . "=" . $d->{$_} } 
           sort { $d->{$a} cmp $d->{$b} } keys %$d);
```

Yes, that's a little dense. Reading it from the end to the start: 

- take the keys of the hash reference *$d*;
- sort them using the anonymous function *\$d->{\$a} cmp \$d->{\$b}*, which is 
    the central Schwartzian Transformation here - sorting by value;
- call the anonymous function *{ \$_ . "=" . \$d->{\$_} }* for each, in which
  + *$_* is the key being compared
  + the string "<key>=<value>" is being constructed from *$_* and *\$d->{\$_}*
  + that string is being returned to map, and map is appending it to a list
- call *join()* with that array of "<key>=<value>" strings
- print it

That emits "*q=2,p=3*".

So if we created some sort of *table.map()* function, perhaps we'd be
able to do the same in Lua:

```lua
local d = { q = 2,
            p = 3 }
print (table.concat(table.map(table.sort(table.keys(d),
                                         function (a,b) return d[a] < d[b]; end),
                              function(t,k) return k .. "=" .. d[k]; end),
                    ";")
      )
```

The *table.map()* function necessary is pretty simple, actually:

```lua
function table:map(f)
   local r = {}
   for _,val in pairs(self) do
      table.insert(r, f(self, val))
   end
   return r
end
```

... at which point the above Lua program also emits "*q=2,p=3*".

Perl's *map()* has more complicated behavior, though; it dynamically
decides if it's aggregating a list or a hash. Since they're both
tables in the Lua context, this is a bit tricky; it's difficult to
discern what the program intends. Instead, it probably makes sense to
pass the table in to the function and let the program choose what to
do:

```lua
function table:map(f)
   local r = {}
   for _,val in pairs(self) do
      f(self, val, r)
   end
   return r
end

local d = { q = 2,
            p = 3 }
print (table.concat(table.map(table.sort(table.keys(d),
                                         function (a,b) return d[a] < d[b]; end),
                              function(t,k,r) table.insert(r, k .. "=" .. d[k]); end),
                    ";")
      )
```

# Other ways to do the same thing

I mentioned that nothing here is new or novel. There are plenty of
other Lua modules that you can pull together to get this same set of
functionality in different ways. Here are some related Lua modules
that I'm aware of which fill some part of this problem space:

## iter

[iter](git://github.com/gordonbrander/iter) offers *map()* as an iterator. I like the general concept of this... but as of this writing, it only supports up to Lua 5.2.

## luatable

[lua-table](https://github.com/Luca96/lua-table) looks like a fairly
functional table replacement. Generally speaking, I'm not a fan of
replacements for tables or arrays in Lua; it's easy to wind up talking
to some external functionality that un-blesses your special table-like
or array-like object. I much prefer having the data be a standard
table; and then build out the functionality you want to be able to
manipulate that data. This leaves the behavior well defined for
built-ins.

## tableutils

[tableutils](https://github.com/telemachus/tableutils) looks really
good to me. It breaks the problem space down to *listutils* and
*hashutils*, recognizing that these two are related and difficult to
differentiate in Lua. Hashutils contains all of keys(), values(),
map(), and reduce(). While it's missing a *sort()* that returns the
table instead of just updating it in place, it does have a *map()*
from listutils that you might be able to shoehorn in to similar
functionality, although it's not immediately obvious to me how.

## penlight

[penlight](https://github.com/stevedonovan/Penlight) is the swiss army
knife for Lua. I would guess that the combination of iterators,
*seq()*, the *Map* class, and *List:sort()* probably do everything
needed - if a bit bulkily, due to the
construct-an-iterator-then-join-all-its-contents pattern that I think
you're stuck with in Penlight.

## Moses

[Moses](http://yonaba.github.io/Moses/) This is the first library I've
looked at that can do what I've written in a fairly obvious way. It's
inspired by understore.js and takes its namesake by convention:

```lua
local _ = require 'moses'
local d = { q = 2, p = 3 }
print(table.concat(_.map(_.sort(_.keys(d), function(a,b) return d[a] < d[b]; end),
                         function(_,v) return v .. "=" .. d[v]; end),
                   ";"
                )
   )
```

The "_" notation weirds me out a little, kind of like using '\$a' or
'\$b' in Perl. Underscore is generally used as a temp variable in Lua;
setting it as a local in module context is like making a global
variable named '\$a' in Perl. It'll work, until it doesn't?

But that's a fairly simple naming convention problem; using 'local
moses = require 'moses' neatly avoids the ugliness and retains all of
the functionality.
