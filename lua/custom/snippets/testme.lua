local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local r = require('luasnip.extras').rep

return {
  lua = {
    s('print_str', {
      t 'print("',
      i(1, 'desrc'),
      t '")',
    }),
    s('print_var1', {
      t 'print("',
      i(1, 'desrc'),
      t ': " .. ',
      i(2, 'the_variable'),
      t ')',
    }),
    s('print_var2', {
      t 'print("',
      i(1, 'the_variable'),
      t ': " .. ',
      r(1),
      t ')',
    }),
    s('print_var3', {
      t 'print("',
      i(1, 'desrc'),
      t ' | ',
      i(2, 'the_variable'),
      t ' : " .. ',
      r(2),
      t ')',
    }),
  },
  markdown = {
    s('daily', {
      t '# DailyX\n',
      t '## ',
      i(1, 'date'),
      t '\n\n',
      t '### ',
      i(2, 'title'),
      t '\n\n',
      t '#### ',
      i(3, 'subtitle'),
      t '\n\n',
      t '##### ',
      i(4, 'author'),
      t '\n\n',
      t '###### ',
      i(5, 'tags'),
      t '\n\n',
      t '###### ',
      i(6, 'summary'),
      t '\n\n',
      t '###### ',
      i(7, 'content'),
      t '\n\n',
    }),
  },
}
