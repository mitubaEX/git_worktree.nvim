local git_worktree = require('git_worktree')

local function handle_command_result(success, error_msg)
  if not success then
    vim.api.nvim_err_writeln("Error: " .. error_msg)
  end
end

vim.api.nvim_create_user_command('GitWorktreeCreate', function(opts)
  local branch = opts.args
  local success, error_msg = git_worktree.create_worktree(branch)
  handle_command_result(success, error_msg)
end, {
  nargs = 1,
  desc = "Create a new worktree for the specified branch"
})

vim.api.nvim_create_user_command('GitWorktreeSwitch', function(opts)
  local branch = opts.args
  local success, error_msg = git_worktree.switch_worktree(branch)
  handle_command_result(success, error_msg)
end, {
  nargs = 1,
  desc = "Switch to the specified branch's worktree"
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
  local pr_number = opts.args
  local success, error_msg = git_worktree.review_pr(pr_number)
  handle_command_result(success, error_msg)
end, {
  nargs = 1,
  desc = "Create worktree for GitHub PR review"
})