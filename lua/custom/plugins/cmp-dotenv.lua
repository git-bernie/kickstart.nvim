return {
  'SergioRibera/cmp-dotenv',
  -- An nvim-cmp source, but this config completes with blink.cmp, which only
  -- queries providers named in `sources.default` (init.lua) -- `dotenv` is not
  -- one of them, and the spec that would have registered it is commented out
  -- at the bottom of init.lua. So this loaded eagerly every launch to provide
  -- a source nothing asked for: 4.3ms, the second-largest startup cost after
  -- init.lua itself. Same reasoning as copilot-cmp.lua.
  -- To reactivate: add 'dotenv' to blink's sources.default first.
  enabled = false,
}
