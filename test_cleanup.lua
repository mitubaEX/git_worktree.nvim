-- Test script for GitWorktreeCleanup
local git_worktree = require('git_worktree')

git_worktree.setup({
  cleanup_buffers = true,
  warn_unsaved = true,
  update_buffers = true,
  copy_envrc = true,
  worktree_dir = ".worktrees",
})

print("\n=== GitWorktreeCleanup Test ===\n")

-- Create multiple test worktrees
print("Creating test worktrees...")
git_worktree.create_worktree("test/cleanup-1", {})
git_worktree.create_worktree("test/cleanup-2", {})
git_worktree.create_worktree("test/cleanup-3", {})

-- Make sure we're on main
git_worktree.switch_worktree("main")

print("\n--- Current worktree list ---")
git_worktree.list_worktrees()

-- Mock vim.fn.input to automatically answer "y"
local original_input = vim.fn.input
vim.fn.input = function(prompt)
  print(prompt .. "y")
  return "y"
end

print("\n--- Running GitWorktreeCleanup ---")
local success, err = git_worktree.cleanup_all_worktrees()

-- Restore original input function
vim.fn.input = original_input

if success then
  print("\n✓ GitWorktreeCleanup - PASSED")
else
  print("\n✗ GitWorktreeCleanup - FAILED: " .. (err or "unknown error"))
end

print("\n--- Final worktree list ---")
git_worktree.list_worktrees()

print("\n=== Test Completed ===\n")

-- Exit with error code if test failed
if not success then
  os.exit(1)
end
