return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  requires = { { 'nvim-lua/plenary.nvim' } },
  config = function()
    require('harpoon'):setup()

    local harpoon = require 'harpoon'
    local extensions = require 'harpoon.extensions'

    harpoon:extend(extensions.builtins.highlight_current_file())

    -- see https://github.com/ThePrimeagen/harpoon/tree/harpoon2
    harpoon:extend {
      UI_CREATE = function(cx)
        vim.keymap.set('n', '<C-v>', function()
          harpoon.ui:select_menu_item { vsplit = true }
        end, { buffer = cx.bufnr })

        vim.keymap.set('n', '<C-x>', function()
          harpoon.ui:select_menu_item { split = true }
        end, { buffer = cx.bufnr })

        vim.keymap.set('n', '<C-t>', function()
          harpoon.ui:select_menu_item { tabedit = true }
        end, { buffer = cx.bufnr })
      end,
    }
    -- TBD & TBH I don't know where to add this section
    local conf = require('telescope.config').values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Harpoon',
          finder = require('telescope.finders').new_table {
            results = file_paths,
          },
          previewer = conf.file_previewer {},
          sorter = conf.generic_sorter {},
        })
        :find()
    end
  end,
  opts = {
    settings = {
      save_on_toggle = true,
      sync_on_ui_close = true,
      key = function()
        return vim.loop.cwd()
      end,
    },
  },
  -- Copied from https://github.com/ThePrimeagen/harpoon/issues/474
  -- Compare: https://www.lazyvim.org/extras/editor/harpoon2
  keys = {
    {
      '<leader>H',
      function()
        -- require('harpoon'):list():append()
        require('harpoon'):list():add()
      end,
      desc = 'harpoon file add',
      silent = false,
    },
    {
      '<leader>h',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = 'harpoon quick menu',
      silent = false,
    },
    {
      '<leader>1',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'harpoon to file 1',
      silent = false,
    },
    {
      '<leader>2',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'harpoon to file 2',
      silent = false,
    },
    {
      '<leader>3',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'harpoon to file 3',
      silent = false,
    },
    {
      '<leader>4',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'harpoon to file 4',
      silent = false,
    },
    {
      '<leader>5',
      function()
        require('harpoon'):list():select(5)
      end,
      desc = 'harpoon to file 5',
      silent = false,
    },
    -- Toggle previous & next buffers stored within Harpoon list
    -- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
    {
      -- '<C-S-P>',
      '<leader>,',
      function()
        require('harpoon'):list():prev()
      end,
      desc = 'harpoon toggle previous buffer in list',
      silent = false,
    },
    -- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
    {
      -- '<C-S-N>',
      '<leader>.',
      function()
        require('harpoon'):list():next()
      end,
      desc = 'harpoon toggle next buffer in list',
      silent = false,
    },
  },
  -- Toggle previous & next buffers stored within Harpoon list
  -- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
  -- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)
}
