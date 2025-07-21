local M = {}

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
  
  if vim.fn.executable("git") ~= 1 then
    vim.api.nvim_err_writeln("git_worktree.nvim requires git to be installed")
    return
  end
  
  print("git_worktree.nvim loaded successfully")
end

return M