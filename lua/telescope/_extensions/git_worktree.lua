local telescope = require('telescope')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local git_worktree = require('git_worktree')

local M = {}

local function get_worktrees()
  local result = vim.fn.system("git worktree list")
  local worktrees = {}
  
  if vim.v.shell_error ~= 0 then
    return {}
  end
  
  for line in result:gmatch("[^\r\n]+") do
    local path, commit, branch_info = line:match("^(.-)%s+(%x+)%s+(.*)$")
    if path and branch_info then
      local branch = branch_info:match("%[(.-)%]") or "HEAD"
      local is_current = branch_info:match("%(bare%)") == nil
      
      table.insert(worktrees, {
        path = path,
        branch = branch,
        commit = commit,
        display = string.format("%-20s %s", branch, path),
        is_current = path == vim.fn.getcwd()
      })
    end
  end
  
  return worktrees
end

local function worktree_picker(opts)
  opts = opts or {}
  
  local worktrees = get_worktrees()
  
  pickers.new(opts, {
    prompt_title = 'Git Worktrees',
    finder = finders.new_table({
      results = worktrees,
      entry_maker = function(entry)
        local display = entry.display
        if entry.is_current then
          display = "* " .. display
        else
          display = "  " .. display
        end
        
        return {
          value = entry,
          display = display,
          ordinal = entry.branch .. " " .. entry.path,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if entry then
          git_worktree.switch_worktree(entry.value.branch)
        end
      end)
      
      map('i', '<C-d>', function()
        local entry = action_state.get_selected_entry()
        if entry and not entry.value.is_current then
          actions.close(prompt_bufnr)
          git_worktree.delete_worktree(entry.value.branch)
        else
          print("Cannot delete current worktree")
        end
      end)
      
      map('i', '<C-n>', function()
        actions.close(prompt_bufnr)
        vim.ui.input({ prompt = 'Branch name: ' }, function(branch)
          if branch and branch ~= "" then
            git_worktree.create_worktree(branch)
          end
        end)
      end)
      
      return true
    end,
  }):find()
end

local function branches_picker(opts)
  opts = opts or {}
  
  local result = vim.fn.system("git branch -a")
  local branches = {}
  
  if vim.v.shell_error ~= 0 then
    print("Error: Not in a git repository")
    return
  end
  
  for line in result:gmatch("[^\r\n]+") do
    local branch = line:match("^%s*%*?%s*(.+)$")
    if branch and not branch:match("^remotes/") then
      branch = branch:gsub("^origin/", "")
      if branch ~= "HEAD" then
        table.insert(branches, branch)
      end
    end
  end
  
  pickers.new(opts, {
    prompt_title = 'Create Worktree',
    finder = finders.new_table({
      results = branches,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if entry then
          git_worktree.create_worktree(entry.value)
        end
      end)
      
      return true
    end,
  }):find()
end

M.worktrees = worktree_picker
M.create_worktree = branches_picker

return telescope.register_extension({
  setup = function(ext_config)
    -- Extension setup
  end,
  exports = {
    git_worktree = worktree_picker,
    worktrees = worktree_picker,
    create = branches_picker,
  },
})