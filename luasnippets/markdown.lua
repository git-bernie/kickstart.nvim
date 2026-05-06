local ls = require 'luasnip'
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  s(
    'daily',
    fmt(
      [[
## {date}
### Jira
{jira}
### Blockers
{blockers}
### Accomplishments
{done}
]],
      {
        date = f(function()
          return os.date '%Y-%m-%d'
        end),
        jira = i(1, '- '),
        blockers = i(2, '- none'),
        done = i(3),
      }
    )
  ),
}
