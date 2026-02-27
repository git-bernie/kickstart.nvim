--[[ 
Useful word motions that are sensitive to camelCase etc. e.g.: 
- `,w` to move to the next word start, 
`,b` to move to the previous word start, 
`,e` to move to the end of the current word, 
`,ge` to move to the end of the previous word, etc.
Why init function?
See https://dev.to/vonheikemen/lazynvim-plugin-configuration-3opi
CamelCaseWords snake_case_words
--]]
return {
  'chaoren/vim-wordmotion',
  event = 'VeryLazy',
  init = function()
    vim.g.wordmotion_prefix = ','
  end,
}
