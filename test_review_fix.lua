-- Test script for GitWorktreeReview fix (branch already exists scenario)
local git_worktree = require('git_worktree')

git_worktree.setup({
  cleanup_buffers = true,
  warn_unsaved = true,
  update_buffers = true,
  copy_envrc = true,
  worktree_dir = ".worktrees",
})

print("\n=== GitWorktreeReview Fix Test ===\n")
print("Testing the scenario where a branch already exists locally")
print("(simulating a second PR review of the same branch)\n")

-- Simulate the scenario:
-- 1. Create a branch and worktree (first PR review)
-- 2. Switch back to main and delete the worktree
-- 3. Try to create the worktree again with the existing branch (second PR review)

local test_branch = "feature/pr-test"

print("--- Step 1: Create branch and worktree (first review) ---")
local success, err = git_worktree.create_worktree(test_branch, {})
if not success then
  print("✗ Failed to create initial worktree: " .. (err or "unknown error"))
  return
end
print("✓ Created worktree for " .. test_branch)

print("\n--- Step 2: Switch back to main and delete worktree ---")
git_worktree.switch_worktree("main")
git_worktree.delete_worktree(test_branch)
print("✓ Deleted worktree (branch still exists)")

print("\n--- Step 3: List branches to confirm branch exists ---")
os.execute("git branch | grep " .. test_branch)

print("\n--- Step 4: Create worktree again with existing branch (second review) ---")
print("This simulates the fixed behavior in review_pr function")
success, err = git_worktree.create_worktree(test_branch, {})

local test_passed = success

if success then
  print("✓ GitWorktreeReview fix - PASSED")
  print("  Successfully created worktree using existing branch")
else
  print("✗ GitWorktreeReview fix - FAILED: " .. (err or "unknown error"))
  print("  This would fail with the old code (fatal: invalid reference)")
end

print("\n--- Cleanup ---")
git_worktree.switch_worktree("main")
git_worktree.delete_worktree(test_branch)
os.execute("git branch -D " .. test_branch .. " 2>/dev/null")

print("\n=== Test Completed ===\n")

-- Exit with error code if test failed
if not test_passed then
  os.exit(1)
end
