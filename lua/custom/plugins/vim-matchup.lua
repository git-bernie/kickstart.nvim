--[=[ 
--|match-up| is a plugin that lets you visualize, navigate, and operate on
matching sets of text.  It is a replacement for the venerable vim plugin
|matchit|.  match-up aims to replicate all of |matchit|'s features, fix a number
of its deficiencies and bugs, and add a few totally new features.  It also
replaces the standard plugin |matchparen|, allowing all of |matchit|'s words to be
highlighted along with the 'matchpairs' symbols such as `()`, `{}`, and `[]`. 
]=]
return {
  'andymass/vim-matchup',
  event = 'BufReadPost',
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
    vim.g.matchup_treesitter_stopline = 1500
    --- = 1 symbols like () will matched, but words like for and end will not
    --- = 2 nothing matched in strings and comments
    -- NOTE: This does not work to my satisfaction:
    -- e.g. PHP nested '}' inside comments or strings seem to break the match
    -- vim.g.matchup_delim_noskips = 0
    vim.g.matchup_treesitter_include_match_words = true
    -- vim.g.matchup_delim_start_plaintext = 1
  end,
}
