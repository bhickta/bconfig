package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. vim.fn.getcwd() .. "/lua/?/init.lua;" .. package.path

local lookup = require("upsc_notes.web_lookup")

local html = [[
<a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fneovim.io%2F&amp;rut=x">Neovim &amp; Lua</a>
<a class="result__snippet" href="x">A &lt;fast&gt; editor with <b>Lua</b>.</a>
<a rel="nofollow" class="result__a" href="//duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.com%2Fguide&amp;rut=y">Guide &#x27;One&#x27;</a>
<a class="result__snippet" href="x">Second result.</a>
]]

local results = lookup.parse_results(html, 6)
if #results ~= 2 then
  error("web lookup should parse result entries")
end
if results[1].title ~= "Neovim & Lua" then
  error("web lookup should decode result titles")
end
if results[1].snippet ~= "A <fast> editor with Lua." then
  error("web lookup should clean result snippets")
end
if results[1].url ~= "https://neovim.io/" then
  error("web lookup should extract destination URLs")
end
if results[2].title ~= "Guide 'One'" then
  error("web lookup should decode numeric HTML entities")
end
