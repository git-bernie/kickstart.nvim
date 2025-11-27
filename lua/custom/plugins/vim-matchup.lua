--[=[ |match-up| is a plugin that lets you visualize, navigate, and operate on
matching sets of text.  It is a replacement for the venerable vim plugin
|matchit|.  match-up aims to replicate all of |matchit|'s features, fix a number
of its deficiencies and bugs, and add a few totally new features.  It also
replaces the standard plugin |matchparen|, allowing all of |matchit|'s words to be
highlighted along with the 'matchpairs' symbols such as `()`, `{}`, and `[]`. 
]=]
return {
  'andymass/vim-matchup',
  enabled = false,
  opts = {
    include_match_words = true,
  },
}
