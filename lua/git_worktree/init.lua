local M = {}

local function execute_command(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to execute command"
  end
  
  local result = handle:read("*a")
  local success, _, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Command failed: " .. cmd
  end
  
  return result:gsub("%s+$", ""), nil
end

local function get_git_root()
  local result, err = execute_command("git rev-parse --show-toplevel")
  if err then
    -- Debug: show what directory we're checking
    local pwd = execute_command("pwd")
    return nil, "Not in a git repository (current dir: " .. (pwd or "unknown") .. ")"
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
    return false, "Failed to create worktree: " .. (result or "Unknown error")
  end
  
  print("Created worktree for branch '" .. branch .. "' at: " .. worktree_path)
  return true, nil
end

function M.switch_worktree(branch)
  local valid, err = validate_branch_name(branch)
  if not valid then
    return false, err
  end
  
  local worktree_path, err = get_worktree_path(branch)
  if err then
    return false, err
  end
  
  local stat = vim.loop.fs_stat(worktree_path)
  if not stat then
    return false, "Worktree for branch '" .. branch .. "' does not exist"
  end
  
  vim.cmd("cd " .. worktree_path)
  print("Switched to worktree: " .. worktree_path)
  return true, nil
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
    return false, "Failed to delete worktree: " .. (result or "Unknown error")
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
  
  local pwd_result, pwd_err = execute_command("pwd")
  if pwd_err then
    return false, pwd_err
  end
  
  print("Current branch: " .. branch_result)
  print("Current worktree: " .. pwd_result)
  return true, nil
end

function M.setup(opts)
  opts = opts or {}
  
  if vim.fn.executable("git") ~= 1 then
    vim.api.nvim_err_writeln("git_worktree.nvim requires git to be installed")
    return
  end
  
  print("git_worktree.nvim loaded successfully")
end

return M