local git_worktree = require("git_worktree")

describe("git_worktree", function()
  local original_cwd

  before_each(function()
    -- Save the original working directory (only once)
    if not original_cwd then
      original_cwd = vim.fn.getcwd()
    end

    -- Always return to original directory before each test
    vim.cmd("cd " .. original_cwd)

    git_worktree.setup({
      cleanup_buffers = true,
      warn_unsaved = true,
      update_buffers = true,
      copy_envrc = true,
      worktree_dir = ".worktrees",
    })
  end)

  describe("setup", function()
    it("initializes with default config", function()
      assert.is_not_nil(git_worktree.config)
      assert.equals(true, git_worktree.config.cleanup_buffers)
      assert.equals(".worktrees", git_worktree.config.worktree_dir)
    end)
  end)

  describe("current_worktree", function()
    it("returns current worktree info", function()
      local success, err = git_worktree.current_worktree()
      assert.is_true(success)
      assert.is_nil(err)
    end)
  end)

  describe("list_worktrees", function()
    it("lists all worktrees", function()
      local success, err = git_worktree.list_worktrees()
      assert.is_true(success)
      assert.is_nil(err)
    end)
  end)

  describe("create_worktree", function()
    local test_branch = "test/feature-create"

    after_each(function()
      -- Cleanup: return to original directory first, then delete test worktree
      vim.cmd("cd " .. original_cwd)
      pcall(git_worktree.delete_worktree, test_branch)
    end)

    it("creates worktree from HEAD", function()
      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)
      assert.is_nil(err)
    end)

    it("creates worktree from default branch", function()
      local success, err = git_worktree.create_worktree(test_branch, {
        from_default_branch = true,
      })
      assert.is_true(success, err)
      assert.is_nil(err)
    end)

    it("creates worktree with command option", function()
      local command_executed = false
      local original_vim_cmd = vim.cmd

      -- Mock vim.cmd to verify command is executed
      vim.cmd = function(cmd)
        if cmd == "echo 'test'" then
          command_executed = true
        else
          original_vim_cmd(cmd)
        end
      end

      local success, err = git_worktree.create_worktree(test_branch, {
        command = "echo 'test'",
      })

      vim.cmd = original_vim_cmd

      assert.is_true(success, err)
      assert.is_true(command_executed, "Command should have been executed")
    end)

    it("rejects invalid branch names", function()
      local success, err = git_worktree.create_worktree("invalid branch!", {})
      assert.is_false(success)
      assert.is_not_nil(err)
      assert.matches("invalid", err:lower())
    end)

    it("handles existing branches", function()
      -- First create
      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      -- Delete worktree but keep branch
      vim.cmd("cd " .. original_cwd)
      git_worktree.delete_worktree(test_branch)

      -- Create again from existing branch
      success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)
    end)
  end)

  describe("switch_worktree", function()
    local test_branch_1 = "test/switch-1"
    local test_branch_2 = "test/switch-2"

    before_each(function()
      -- Create test worktrees
      git_worktree.create_worktree(test_branch_1, {})
      git_worktree.create_worktree(test_branch_2, {})
    end)

    after_each(function()
      -- Cleanup: return to original directory first
      vim.cmd("cd " .. original_cwd)
      pcall(git_worktree.delete_worktree, test_branch_1)
      pcall(git_worktree.delete_worktree, test_branch_2)
    end)

    it("switches between worktrees", function()
      local success, err = git_worktree.switch_worktree(test_branch_1)
      assert.is_true(success, err)

      success, err = git_worktree.switch_worktree(test_branch_2)
      assert.is_true(success, err)

      -- Switch back to test_branch_1 to test switching again
      success, err = git_worktree.switch_worktree(test_branch_1)
      assert.is_true(success, err)
    end)

    it("switches with command option", function()
      local command_executed = false
      local original_vim_cmd = vim.cmd

      vim.cmd = function(cmd)
        if cmd == "echo 'switched'" then
          command_executed = true
        else
          original_vim_cmd(cmd)
        end
      end

      local success, err = git_worktree.switch_worktree(test_branch_1, {
        command = "echo 'switched'",
      })

      vim.cmd = original_vim_cmd

      assert.is_true(success, err)
      assert.is_true(command_executed, "Command should have been executed")
    end)

    it("fails for non-existent worktree", function()
      local success, err = git_worktree.switch_worktree("non/existent")
      assert.is_false(success)
      assert.is_not_nil(err)
    end)
  end)

  describe("delete_worktree", function()
    local test_branch = "test/delete"

    before_each(function()
      git_worktree.create_worktree(test_branch, {})
      -- Return to original directory so we can delete the worktree
      vim.cmd("cd " .. original_cwd)
    end)

    after_each(function()
      -- Cleanup: ensure we're back in original directory
      vim.cmd("cd " .. original_cwd)
    end)

    it("deletes worktree", function()
      local success, err = git_worktree.delete_worktree(test_branch)
      assert.is_true(success, err)
    end)

    it("fails for non-existent worktree", function()
      local success, err = git_worktree.delete_worktree("non/existent")
      assert.is_false(success)
      assert.is_not_nil(err)
    end)
  end)

  describe("command execution", function()
    local test_branch = "test/commands"

    after_each(function()
      vim.cmd("cd " .. original_cwd)
      pcall(git_worktree.delete_worktree, test_branch)
    end)

    it("executes single command", function()
      local executed_commands = {}
      local original_vim_cmd = vim.cmd

      vim.cmd = function(cmd)
        if cmd:match("^echo") then
          table.insert(executed_commands, cmd)
        else
          original_vim_cmd(cmd)
        end
      end

      git_worktree.create_worktree(test_branch, {
        command = "echo 'test'",
      })

      vim.cmd = original_vim_cmd

      assert.equals(1, #executed_commands)
      assert.equals("echo 'test'", executed_commands[1])
    end)

    it("executes multiple commands", function()
      local executed_commands = {}
      local original_vim_cmd = vim.cmd

      vim.cmd = function(cmd)
        if cmd:match("^echo") then
          table.insert(executed_commands, cmd)
        else
          original_vim_cmd(cmd)
        end
      end

      git_worktree.create_worktree(test_branch, {
        command = { "echo 'first'", "echo 'second'" },
      })

      vim.cmd = original_vim_cmd

      assert.equals(2, #executed_commands)
      assert.equals("echo 'first'", executed_commands[1])
      assert.equals("echo 'second'", executed_commands[2])
    end)
  end)
end)
