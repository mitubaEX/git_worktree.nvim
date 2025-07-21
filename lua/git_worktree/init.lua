local M = {}

-- Default configuration
M.config = {
  cleanup_buffers = true,  -- Clean up buffers when switching worktrees
  warn_unsaved = true,     -- Warn about unsaved changes
  update_buffers = true,   -- Update buffer paths to match new worktree
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

local function branch_exists(branch)
  -- Check local branches first
  local result, err = execute_command("git show-ref --verify --quiet refs/heads/" .. branch)
  if not err then
    return true, "local"
  end
  
  -- Check remote branches (try common remotes)
  local remotes = {"origin", "upstream"}
  for _, remote in ipairs(remotes) do
    result, err = execute_command("git show-ref --verify --quiet refs/remotes/" .. remote .. "/" .. branch)
    if not err then
      return true, "remote", remote
    end
  end
  
  return false, nil, nil
end

local function create_branch_from_current(branch)
  -- Create a new branch from current HEAD
  local result, err = execute_command("git branch " .. branch)
  if err then
    return false, "Failed to create branch: " .. err
  end
  return true, nil
end

local function update_buffers(new_path)
  -- Skip if both cleanup and update are disabled
  if not M.config.cleanup_buffers and not M.config.update_buffers then
    return
  end
  
  -- Get current working directory before switch
  local old_cwd = vim.fn.getcwd()
  
  -- Get all buffers
  local buffers = vim.api.nvim_list_bufs()
  local closed_count = 0
  local unsaved_count = 0
  local updated_count = 0
  local failed_update_count = 0
  
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
          
          if M.config.update_buffers then
            -- Calculate relative path from old worktree
            local relative_path = buf_name:sub(#old_cwd + 2) -- +2 to skip the trailing slash
            local new_file_path = new_path .. "/" .. relative_path
            
            -- Check if file exists in new worktree
            local stat = vim.loop.fs_stat(new_file_path)
            if stat then
              -- Update buffer to point to new file
              local success = pcall(function()
                vim.api.nvim_buf_set_name(buf, new_file_path)
                -- Reload buffer content from new location
                vim.api.nvim_buf_call(buf, function()
                  vim.cmd("edit!")
                end)
              end)
              
              if success then
                updated_count = updated_count + 1
              else
                failed_update_count = failed_update_count + 1
                if M.config.warn_unsaved then
                  print("Warning: Failed to update buffer " .. vim.fn.fnamemodify(buf_name, ':t'))
                end
              end
            else
              -- File doesn't exist in new worktree
              if buf_modified then
                unsaved_count = unsaved_count + 1
                if M.config.warn_unsaved then
                  print("Warning: Buffer " .. vim.fn.fnamemodify(buf_name, ':t') .. " has unsaved changes and doesn't exist in new worktree")
                end
              else
                -- Clean up buffer if file doesn't exist in new worktree and no unsaved changes
                if M.config.cleanup_buffers then
                  local success = pcall(vim.api.nvim_buf_delete, buf, { force = false })
                  if success then
                    closed_count = closed_count + 1
                  end
                end
              end
            end
          else
            -- Just cleanup without updating
            if buf_modified then
              unsaved_count = unsaved_count + 1
              if M.config.warn_unsaved then
                print("Warning: Buffer " .. vim.fn.fnamemodify(buf_name, ':t') .. " has unsaved changes")
              end
            else
              if M.config.cleanup_buffers then
                local success = pcall(vim.api.nvim_buf_delete, buf, { force = false })
                if success then
                  closed_count = closed_count + 1
                end
              end
            end
          end
        end
      end
    end
  end
  
  -- Show summary
  if updated_count > 0 or closed_count > 0 or unsaved_count > 0 or failed_update_count > 0 then
    local msg = "Buffer update: "
    local parts = {}
    
    if updated_count > 0 then
      table.insert(parts, updated_count .. " updated")
    end
    if closed_count > 0 then
      table.insert(parts, closed_count .. " closed")
    end
    if unsaved_count > 0 then
      table.insert(parts, unsaved_count .. " unsaved (kept)")
    end
    if failed_update_count > 0 then
      table.insert(parts, failed_update_count .. " failed")
    end
    
    print(msg .. table.concat(parts, ", "))
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
  
  -- Check if branch exists
  local exists, branch_type, remote_name = branch_exists(branch)
  local worktree_cmd
  
  if exists then
    if branch_type == "local" then
      -- Branch exists locally, create worktree from it
      worktree_cmd = "git worktree add " .. worktree_path .. " " .. branch
      print("Creating worktree from existing local branch '" .. branch .. "'...")
    elseif branch_type == "remote" then
      -- Branch exists on remote, create worktree and track remote branch
      local remote = remote_name or "origin"
      worktree_cmd = "git worktree add " .. worktree_path .. " -b " .. branch .. " " .. remote .. "/" .. branch
      print("Creating worktree from remote branch '" .. remote .. "/" .. branch .. "'...")
    end
  else
    -- Branch doesn't exist, create new branch and worktree from current HEAD
    worktree_cmd = "git worktree add " .. worktree_path .. " -b " .. branch
    print("Creating new branch '" .. branch .. "' and worktree from current HEAD...")
  end
  
  -- Execute the worktree creation command
  local result, cmd_err = execute_command(worktree_cmd)
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
    -- Update/cleanup buffers from old worktree before switching
    update_buffers(worktree_path)
    
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
      -- Update/cleanup buffers from old worktree before switching
      update_buffers(expected_path)
      
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