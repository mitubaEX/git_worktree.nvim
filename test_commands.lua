-- Test script for git_worktree.nvim commands
local git_worktree = require('git_worktree')

-- Setup the plugin
git_worktree.setup({
  cleanup_buffers = true,
  warn_unsaved = true,
  update_buffers = true,
  copy_envrc = true,
  worktree_dir = ".worktrees",
})

print("\n=== Git Worktree Plugin Test Suite ===\n")

-- Track test results
local total_tests = 0
local failed_tests = 0

-- Helper function to print test results
local function test_result(name, success, error_msg)
  total_tests = total_tests + 1
  if success then
    print("✓ " .. name .. " - PASSED")
  else
    print("✗ " .. name .. " - FAILED: " .. (error_msg or "unknown error"))
    failed_tests = failed_tests + 1
  end
  return success
end

-- Test 1: Current worktree
print("\n--- Test 1: GitWorktreeCurrent ---")
local success, err = git_worktree.current_worktree()
test_result("GitWorktreeCurrent", success, err)

-- Test 2: List worktrees
print("\n--- Test 2: GitWorktreeList ---")
success, err = git_worktree.list_worktrees()
test_result("GitWorktreeList", success, err)

-- Test 3: Create new worktree from current HEAD
print("\n--- Test 3: GitWorktreeCreate (new branch from HEAD) ---")
local test_branch_1 = "test/feature-1"
success, err = git_worktree.create_worktree(test_branch_1, {})
test_result("GitWorktreeCreate (from HEAD)", success, err)

-- Test 4: Create new worktree from default branch
print("\n--- Test 4: GitWorktreeCreate (new branch from default) ---")
local test_branch_2 = "test/feature-2"
success, err = git_worktree.create_worktree(test_branch_2, { from_default_branch = true })
test_result("GitWorktreeCreate (from default)", success, err)

-- Test 5: Switch to first test worktree
print("\n--- Test 5: GitWorktreeSwitch ---")
success, err = git_worktree.switch_worktree(test_branch_1)
test_result("GitWorktreeSwitch", success, err)

-- Test 6: Current worktree (should show test branch)
print("\n--- Test 6: GitWorktreeCurrent (after switch) ---")
success, err = git_worktree.current_worktree()
test_result("GitWorktreeCurrent (after switch)", success, err)

-- Test 7: Switch back to main
print("\n--- Test 7: GitWorktreeSwitch (back to main) ---")
success, err = git_worktree.switch_worktree("main")
test_result("GitWorktreeSwitch (to main)", success, err)

-- Test 8: Delete first test worktree
print("\n--- Test 8: GitWorktreeDelete ---")
success, err = git_worktree.delete_worktree(test_branch_1)
test_result("GitWorktreeDelete", success, err)

-- Test 9: List worktrees (should show remaining)
print("\n--- Test 9: GitWorktreeList (after delete) ---")
success, err = git_worktree.list_worktrees()
test_result("GitWorktreeList (after delete)", success, err)

-- Test 10: Create worktree from existing branch (should reuse branch)
print("\n--- Test 10: GitWorktreeCreate (existing branch) ---")
local test_branch_3 = "test/existing"
-- First create the branch and worktree
success, err = git_worktree.create_worktree(test_branch_3, {})
if success then
  -- Switch back to main and delete the worktree
  git_worktree.switch_worktree("main")
  git_worktree.delete_worktree(test_branch_3)
  -- Now try to create worktree again with the existing branch
  success, err = git_worktree.create_worktree(test_branch_3, {})
  test_result("GitWorktreeCreate (existing branch)", success, err)
else
  test_result("GitWorktreeCreate (existing branch) - Setup failed", false, err)
end

-- Test 11: Error handling - invalid branch name
print("\n--- Test 11: Error Handling (invalid branch name) ---")
success, err = git_worktree.create_worktree("invalid branch name!", {})
test_result("Error handling (should fail)", not success, "Should reject invalid branch name")

-- Test 12: Error handling - switch to non-existent worktree
print("\n--- Test 12: Error Handling (non-existent worktree) ---")
success, err = git_worktree.switch_worktree("non/existent/branch")
test_result("Error handling (should fail)", not success, "Should fail for non-existent worktree")

-- Cleanup: Delete test worktrees
print("\n--- Cleanup ---")
print("Cleaning up test worktrees...")
git_worktree.switch_worktree("main")
git_worktree.delete_worktree(test_branch_2)
git_worktree.delete_worktree(test_branch_3)

print("\n--- Test Summary ---")
print(string.format("Total tests: %d", total_tests))
print(string.format("Passed: %d", total_tests - failed_tests))
print(string.format("Failed: %d", failed_tests))

print("\nNote: GitWorktreeReview and GitWorktreeCleanup require manual testing:")
print("  - GitWorktreeReview: Requires GitHub CLI and a real PR number")
print("  - GitWorktreeCleanup: Requires user confirmation (interactive)")

print("\n=== Test Suite Completed ===\n")

-- Exit with error code if any tests failed
if failed_tests > 0 then
  os.exit(1)
end
