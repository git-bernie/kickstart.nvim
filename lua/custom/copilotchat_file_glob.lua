--[[ https://mihamina.rktmb.org/2025/08/copilotchat-globfile-configuration.html 
-- 
-- How to use #file_glob in chat
-- Inside an open Copilot Chat buffer, type a prompt and include a glob pattern. A few examples:
--
-- Please review the following TypeScript utils and suggest a common refactor.
-- #file_glob:src/utils/**/*.ts
-- 
-- Generate Jest tests for all reducers.
-- #file_glob:src/store/**/reducers/*.ts
-- 
-- Summarize the docs.
-- #file_glob:docs/**/*.md
--]]
return {
  file_glob = {
    group = 'copilot',
    uri = 'files://glob_contents/{pattern}',
    description = 'Includes the full contents of every file matching a specified glob pattern.',
    schema = {
      type = 'object',
      required = { 'pattern' },
      properties = {
        pattern = {
          type = 'string',
          description = 'Glob pattern to match files.',
          default = '**/*',
        },
      },
    },
    resolve = function(input, source)
      local files = require('CopilotChat.utils.files').glob(source.cwd(), {
        pattern = input.pattern,
      })

      local resources = {}
      for _, file_path in ipairs(files) do
        local data, mimetype = require('CopilotChat.resources').get_file(file_path)
        if data then
          table.insert(resources, {
            uri = 'file://' .. file_path,
            name = file_path,
            mimetype = mimetype,
            data = data,
          })
        end
      end

      return resources
    end,
  },
}
