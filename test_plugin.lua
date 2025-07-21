#!/usr/bin/env nvim -l

-- Test script for git_worktree.nvim
-- Usage: nvim -l test_plugin.lua

-- Add current directory to runtime path
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Load the plugin
local git_worktree = require('git_worktree')

-- Test in the test-repo directory
print("=== Testing git_worktree.nvim ===")

-- Change to test repo directory
local success = pcall(function()
    vim.cmd("cd test-repo")
end)

if not success then
    print("ERROR: Could not change to test-repo directory")
    os.exit(1)
end

print("Changed to test-repo directory")
print("Current directory: " .. vim.fn.getcwd())

-- Test 1: List current worktrees
print("\n1. Testing GitWorktreeList:")
local success, err = git_worktree.list_worktrees()
if not success then
    print("ERROR: " .. err)
end

-- Test 2: Show current worktree
print("\n2. Testing GitWorktreeCurrent:")
local success, err = git_worktree.current_worktree()
if not success then
    print("ERROR: " .. err)
end

-- Test 3: Create a worktree
print("\n3. Testing GitWorktreeCreate:")
local success, err = git_worktree.create_worktree("feature-test")
if not success then
    print("ERROR: " .. err)
else
    print("Successfully created worktree!")
end

-- Test 4: List worktrees again to see the new one
print("\n4. Listing worktrees after creation:")
local success, err = git_worktree.list_worktrees()
if not success then
    print("ERROR: " .. err)
end

-- Test 5: Switch to the new worktree
print("\n5. Testing GitWorktreeSwitch:")
local success, err = git_worktree.switch_worktree("feature-test")
if not success then
    print("ERROR: " .. err)
else
    print("Successfully switched worktree!")
    print("New working directory: " .. vim.fn.getcwd())
end

-- Test 6: Switch back to main
print("\n6. Switching back to main:")
local success, err = git_worktree.switch_worktree("main")
if not success then
    print("ERROR: " .. err)
else
    print("Successfully switched back to main!")
end

-- Test 7: Clean up - delete the test worktree
print("\n7. Cleaning up - deleting test worktree:")
local success, err = git_worktree.delete_worktree("feature-test")
if not success then
    print("ERROR: " .. err)
else
    print("Successfully deleted worktree!")
end

print("\n=== Test completed ===")