local M = {}

-- Default configuration
M.config = {
  cleanup_buffers = true,  -- Clean up buffers when switching worktrees
  warn_unsaved = true,     -- Warn about unsaved changes
}

local function execute_command(cmd)
  -- Use vim.fn.system for better Neovim integration
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 then
    return nil, "Command failed: " .. cmd .. " (exit code: " .. exit_code .. ")"
  end
  
  -- Remove trailing whitespace
  return result:gsub("%s+$", ""), nil
end

local function get_git_root()
  -- Use Neovim's built-in function to get current working directory
  local cwd = vim.fn.getcwd()
  
  local result, err = execute_command("git rev-parse --show-toplevel")
  if err then
    return nil, "Not in a git repository (current dir: " .. cwd .. ")"
  end
  return result, nil
end

local function validate_branch_name(branch)
  if not branch or branch == "" then
    return false, "Branch name cannot be empty"
  end
  
  if branch:match("[^%w%-%._/]") then
    return false, "Branch name contains invalid characters"
  end
  
  return true, nil
end

local function get_worktree_path(branch)
  local git_root, err = get_git_root()
  if err then
    return nil, err
  end
  
  local safe_branch = branch:gsub("/", "_")
  return git_root .. "_" .. safe_branch, nil
end

local function find_worktree_location(branch)
  -- Get the list of worktrees and find where this branch is located
  local result, err = execute_command("git worktree list")
  if err then
    return nil, err
  end
  
  -- Parse the worktree list to find the branch location
  for line in result:gmatch("[^\r\n]+") do
    -- Format: /path/to/worktree  commit_hash [branch_name]
    local path, commit, branch_info = line:match("^(.-)%s+(%x+)%s+(.*)$")
    if path and branch_info then
      -- Extract branch name from [branch_name] format
      local worktree_branch = branch_info:match("%[(.-)%]")
      if worktree_branch == branch then
        return path, nil
      end
    end
  end
  
  return nil, "Worktree for branch '" .. branch .. "' not found"
end

local function cleanup_buffers(new_path)
  -- Skip cleanup if disabled
  if not M.config.cleanup_buffers then
    return
  end
  
  -- Get current working directory before switch
  local old_cwd = vim.fn.getcwd()
  
  -- Get all buffers
  local buffers = vim.api.nvim_list_bufs()
  local closed_count = 0
  local unsaved_count = 0
  
  for _, buf in ipairs(buffers) do
    -- Check if buffer is valid and loaded
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      
      -- If buffer has a name and is from the old directory
      if buf_name and buf_name ~= "" then
        -- Check if buffer path starts with old working directory
        if buf_name:find("^" .. vim.pesc(old_cwd)) then
          -- Check if buffer has unsaved changes
          local buf_modified = vim.api.nvim_buf_get_option(buf, 'modified')
          
          if buf_modified then
            unsaved_count = unsaved_count + 1
            if M.config.warn_unsaved then
              print("Warning: Buffer " .. vim.fn.fnamemodify(buf_name, ':t') .. " has unsaved changes")
            end
          else
            -- Close buffer if no unsaved changes
            local success = pcall(vim.api.nvim_buf_delete, buf, { force = false })
            if success then
              closed_count = closed_count + 1
            end
          end
        end
      end
    end
  end
  
  -- Show cleanup summary
  if closed_count > 0 or unsaved_count > 0 then
    local msg = "Buffer cleanup: "
    if closed_count > 0 then
      msg = msg .. closed_count .. " closed"
    end
    if unsaved_count > 0 then
      if closed_count > 0 then msg = msg .. ", " end
      msg = msg .. unsaved_count .. " unsaved (kept)"
    end
    print(msg)
  end
end

function M.create_worktree(branch)
  local valid, err = validate_branch_name(branch)
  if not valid then
    return false, err
  end
  
  local worktree_path, err = get_worktree_path(branch)
  if err then
    return false, err
  end
  
  local result, cmd_err = execute_command("git worktree add " .. worktree_path .. " " .. branch)
  if cmd_err then
    return false, "Failed to create worktree: " .. cmd_err
  end
  
  print("Created worktree for branch '" .. branch .. "' at: " .. worktree_path)
  return true, nil
end

function M.switch_worktree(branch)
  local valid, err = validate_branch_name(branch)
  if not valid then
    return false, err
  end
  
  -- First, try to find the branch in the existing worktree list
  local worktree_path, find_err = find_worktree_location(branch)
  
  if worktree_path then
    -- Clean up buffers from old worktree before switching
    cleanup_buffers(worktree_path)
    
    -- Found the branch in worktree list, switch to it
    vim.cmd("cd " .. worktree_path)
    print("Switched to worktree: " .. worktree_path .. " [" .. branch .. "]")
    return true, nil
  else
    -- Branch not found in worktree list, try the expected worktree path
    local expected_path, path_err = get_worktree_path(branch)
    if path_err then
      return false, path_err
    end
    
    local stat = vim.loop.fs_stat(expected_path)
    if stat then
      -- Clean up buffers from old worktree before switching
      cleanup_buffers(expected_path)
      
      vim.cmd("cd " .. expected_path)
      print("Switched to worktree: " .. expected_path)
      return true, nil
    else
      return false, "Worktree for branch '" .. branch .. "' does not exist. Use :GitWorktreeCreate " .. branch .. " to create it first."
    end
  end
end

function M.delete_worktree(branch)
  local valid, err = validate_branch_name(branch)
  if not valid then
    return false, err
  end
  
  local worktree_path, err = get_worktree_path(branch)
  if err then
    return false, err
  end
  
  local result, cmd_err = execute_command("git worktree remove " .. worktree_path)
  if cmd_err then
    return false, "Failed to delete worktree: " .. cmd_err
  end
  
  print("Deleted worktree for branch: " .. branch)
  return true, nil
end

function M.list_worktrees()
  local result, err = execute_command("git worktree list")
  if err then
    return false, err
  end
  
  print("Git worktrees:")
  print(result)
  return true, nil
end

function M.current_worktree()
  local branch_result, branch_err = execute_command("git branch --show-current")
  if branch_err then
    return false, branch_err
  end
  
  -- Use Neovim's built-in function instead of pwd command
  local current_dir = vim.fn.getcwd()
  
  print("Current branch: " .. branch_result)
  print("Current worktree: " .. current_dir)
  return true, nil
end

function M.setup(opts)
  opts = opts or {}
  
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  if vim.fn.executable("git") ~= 1 then
    vim.api.nvim_err_writeln("git_worktree.nvim requires git to be installed")
    return
  end
  
  print("git_worktree.nvim loaded successfully")
end

return M