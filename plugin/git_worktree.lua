local git_worktree = require('git_worktree')

local function handle_command_result(success, error_msg)
  if not success then
    vim.api.nvim_err_writeln("Error: " .. error_msg)
  end
end

vim.api.nvim_create_user_command('GitWorktreeCreate', function(opts)
  local create_opts = {}
  local branch = nil
  local i = 1

  -- Parse flags and arguments
  while i <= #opts.fargs do
    local arg = opts.fargs[i]
    if arg == "--from-default" then
      create_opts.from_default_branch = true
      i = i + 1
    elseif arg == "--command" or arg == "--cmd" then
      -- Next argument is the command
      i = i + 1
      if i <= #opts.fargs then
        create_opts.command = opts.fargs[i]
        i = i + 1
      end
    else
      -- This is the branch name
      branch = arg
      i = i + 1
    end
  end

  if not branch then
    vim.api.nvim_err_writeln("Error: Branch name is required")
    return
  end

  local success, error_msg = git_worktree.create_worktree(branch, create_opts)
  handle_command_result(success, error_msg)
end, {
  nargs = '+',
  desc = "Create a new worktree for the specified branch. Use --from-default to create from default branch, --command to run nvim command after creation"
})

vim.api.nvim_create_user_command('GitWorktreeSwitch', function(opts)
  local switch_opts = {}
  local branch = nil
  local i = 1

  -- Parse flags and arguments
  while i <= #opts.fargs do
    local arg = opts.fargs[i]
    if arg == "--command" or arg == "--cmd" then
      -- Next argument is the command
      i = i + 1
      if i <= #opts.fargs then
        switch_opts.command = opts.fargs[i]
        i = i + 1
      end
    else
      -- This is the branch name
      branch = arg
      i = i + 1
    end
  end

  if not branch then
    vim.api.nvim_err_writeln("Error: Branch name is required")
    return
  end

  local success, error_msg = git_worktree.switch_worktree(branch, switch_opts)
  handle_command_result(success, error_msg)
end, {
  nargs = '+',
  desc = "Switch to the specified branch's worktree. Use --command to run nvim command after switching"
})

vim.api.nvim_create_user_command('GitWorktreeDelete', function(opts)
  local branch = opts.args
  local success, error_msg = git_worktree.delete_worktree(branch)
  handle_command_result(success, error_msg)
end, {
  nargs = 1,
  desc = "Delete the worktree for the specified branch"
})

vim.api.nvim_create_user_command('GitWorktreeList', function()
  local success, error_msg = git_worktree.list_worktrees()
  handle_command_result(success, error_msg)
end, {
  nargs = 0,
  desc = "List all worktrees in the current repository"
})

vim.api.nvim_create_user_command('GitWorktreeCurrent', function()
  local success, error_msg = git_worktree.current_worktree()
  handle_command_result(success, error_msg)
end, {
  nargs = 0,
  desc = "Show the current branch and its worktree"
})

vim.api.nvim_create_user_command('GitWorktreeReview', function(opts)
  local review_opts = {}
  local pr_number = nil
  local i = 1

  -- Parse flags and arguments
  while i <= #opts.fargs do
    local arg = opts.fargs[i]
    if arg == "--command" or arg == "--cmd" then
      -- Next argument is the command
      i = i + 1
      if i <= #opts.fargs then
        review_opts.command = opts.fargs[i]
        i = i + 1
      end
    else
      -- This is the PR number
      pr_number = arg
      i = i + 1
    end
  end

  if not pr_number then
    vim.api.nvim_err_writeln("Error: PR number is required")
    return
  end

  local success, error_msg = git_worktree.review_pr(pr_number, review_opts)
  handle_command_result(success, error_msg)
end, {
  nargs = '+',
  desc = "Create worktree for GitHub PR review. Use --command to run nvim command after creation"
})

vim.api.nvim_create_user_command('GitWorktreeCleanup', function()
  local success, error_msg = git_worktree.cleanup_all_worktrees()
  handle_command_result(success, error_msg)
end, {
  nargs = 0,
  desc = "Remove all worktrees except current (with confirmation)"
})