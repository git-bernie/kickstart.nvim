--[=[
--|match-up| is a plugin that lets you visualize, navigate, and operate on
matching sets of text.  It is a replacement for the venerable vim plugin
|matchit|.  match-up aims to replicate all of |matchit|'s features, fix a number
of its deficiencies and bugs, and add a few totally new features.  It also
replaces the standard plugin |matchparen|, allowing all of |matchit|'s words to be
highlighted along with the 'matchpairs' symbols such as `()`, `{}`, and `[]`.
]=]
-- Names of treesitter languages whose vim-matchup matchup.scm queries reference
-- node types that aren't in the installed/injected parser, firing E5108 on
-- CursorMoved. We override query lookup to make matchup see "no query" for these
-- and short-circuit to no-matches via `if not query then return {} end`.
--
-- Add a lang here if a new one shows up in the error stack.
local broken_matchup_langs = { 'quote', 'html', 'vue', 'svelte', 'templ' }

-- Install the wrap in init (runs at nvim startup, BEFORE the plugin loads and
-- BEFORE its memoize cache has a chance to fill). We wrap get_files rather than
-- get because:
--   * get_files is NOT memoized (clean replacement, no cache invalidation needed)
--   * get IS memoized AND matchup itself calls `vim.treesitter.query.get:clear()`
--     at matchup.vim:436 to invalidate the cache on save — replacing `get` with a
--     plain function strips that `:clear` method and breaks the save-side hook
--   * making get_files return {} for the offending pairs causes get's query_string
--     to be "" → returns nil → matchup's get_lang_matches returns {} cleanly
local function install_matchup_query_wrap()
  if vim.g._matchup_query_get_files_patched then
    return
  end
  local orig_get_files = vim.treesitter.query.get_files
  vim.treesitter.query.get_files = function(lang, query_name, is_included)
    if query_name == 'matchup' and vim.list_contains(broken_matchup_langs, lang) then
      return {}
    end
    return orig_get_files(lang, query_name, is_included)
  end
  vim.g._matchup_query_get_files_patched = true
end

return {
  'andymass/vim-matchup',
  event = 'BufReadPost',
  init = install_matchup_query_wrap,
  config = function()
    -- Disable treesitter integration until nvim-treesitter migrates to main branch (nvim 0.12 compat).
    -- IMPORTANT: must be `false`, not `0`. matchup checks `if enabled` in Lua, and in
    -- Lua `0` is truthy (only `nil` and `false` are falsy). Setting `0` here looked
    -- correct but matchup still treated TS as enabled, which (a) ran the broken
    -- TS queries and (b) filtered b:match_words down to only TS-confirmed scopes —
    -- stripping the HTML tag pattern and breaking `%` on <button> ↔ </button>.
    vim.g.matchup_treesitter_enabled = false
    vim.g.matchup_treesitter_enable_quotes = false
    vim.g.matchup_treesitter_disabled = { 'quote' }
    vim.g.matchup_matchparen_offscreen = { method = 'popup' }
    vim.g.matchup_treesitter_stopline = 1500
    --- = 1 symbols like () will matched, but words like for and end will not
    --- = 2 nothing matched in strings and comments
    -- NOTE: This does not work to my satisfaction:
    -- e.g. PHP nested '}' inside comments or strings seem to break the match
    -- vim.g.matchup_delim_noskips = 0
    vim.g.matchup_treesitter_include_match_words = true
    -- vim.g.matchup_delim_start_plaintext = 1

    -- Defensive: re-install the query wrap if init didn't run (e.g. matchup loaded
    -- through a different lazy trigger). install_matchup_query_wrap is idempotent.
    install_matchup_query_wrap()
  end,
}
