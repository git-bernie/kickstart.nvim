--[[
FIXME: Storing sensitive information like API tokens in plain text files can pose security risks.
Consider using a secure vault or environment variable management system to handle sensitive data.
E.g. local api_token = vim.fn.system('op read "op://Vault/Jira API Token/credential"'):gsub('%s+$', '')
]]
return {
  'letieu/jira.nvim',
  opts = function()
    -- Read a key from a .env file
    local function read_env_file(path, key)
      local file = io.open(path, 'r')
      if not file then
        return nil
      end
      for line in file:lines() do
        local k, v = line:match '^([^#][^=]*)=(.+)$'
        if k and k:match '^%s*(.-)%s*$' == key then
          file:close()
          v = v:match '^%s*(.-)%s*$' -- trim whitespace
          v = v:match '^["\'](.+)["\']$' or v -- strip surrounding quotes
          return v
        end
      end
      file:close()
      return nil
    end
    -- Check project .env first, then fall back to nvim config .env
    local project_env = vim.fn.getcwd() .. '/.env'
    local global_env = vim.fn.stdpath 'config' .. '/.env'

    --- Get JIRA_API_TOKEN from .env files
    local api_token = read_env_file(project_env, 'JIRA_API_TOKEN') or read_env_file(global_env, 'JIRA_API_TOKEN')
    if not api_token then
      vim.notify('JIRA_API_TOKEN not found in .env (checked project and nvim config)', vim.log.levels.ERROR)
    end
    return {
      jira = {
        base = 'https://loanconnect.atlassian.net',
        email = 'bdavid@assetdirect.io',
        token = api_token,
        type = 'basic',
        api_version = '3',
        limit = 200,
      },
      active_sprint_query = "project = '%s' AND sprint in openSprints() ORDER BY Rank ASC",
      queries = {
        ['Next sprint'] = "project = '%s' AND sprint in futureSprints() ORDER BY Rank ASC",
        ['Backlog'] = "project = '%s' AND (issuetype IN standardIssueTypes() OR issuetype = Sub-task) AND (sprint IS EMPTY OR sprint NOT IN openSprints()) AND statusCategory != Done ORDER BY Rank ASC",
        ['My Tasks'] = 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC',
      },
      projects = { ['AD'] = {} },
    }
  end,
}
