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

  describe("worktreeinclude", function()
    local test_branch = "test/include"
    local include_path
    local extra_file_path
    local extra_dir_path
    local nested_file_path

    before_each(function()
      include_path = original_cwd .. "/.worktreeinclude"
      extra_file_path = original_cwd .. "/.worktree-extra"
      extra_dir_path = original_cwd .. "/.worktree-extras"
      nested_file_path = extra_dir_path .. "/nested.txt"

      -- Clean up any leftover state from a prior aborted run
      local worktree_path = original_cwd .. "/.worktrees/test_include"
      vim.fn.system("git worktree remove --force " .. worktree_path)
      vim.fn.system("git branch -D " .. test_branch)

      -- Create source artifacts to be copied via .worktreeinclude
      vim.fn.writefile({ "extra-file" }, extra_file_path)
      vim.fn.mkdir(extra_dir_path, "p")
      vim.fn.writefile({ "nested" }, nested_file_path)
    end)

    after_each(function()
      vim.cmd("cd " .. original_cwd)
      -- Worktrees populated by .worktreeinclude contain untracked files,
      -- so `git worktree remove` would refuse them. Force-remove instead.
      local worktree_path = original_cwd .. "/.worktrees/test_include"
      vim.fn.system("git worktree remove --force " .. worktree_path)
      vim.fn.system("git branch -D " .. test_branch)
      os.remove(include_path)
      os.remove(extra_file_path)
      os.remove(nested_file_path)
      pcall(vim.fn.delete, extra_dir_path, "rf")
    end)

    it("copies files and directories listed in .worktreeinclude", function()
      vim.fn.writefile({
        "# comment line",
        "",
        ".worktree-extra",
        ".worktree-extras",
      }, include_path)

      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      local worktree_path = vim.fn.getcwd()
      assert.is_not_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extra"))
      assert.is_not_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extras"))
      assert.is_not_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extras/nested.txt"))
    end)

    it("skips entries whose source does not exist", function()
      vim.fn.writefile({
        ".worktree-extra",
        "definitely-not-there.txt",
      }, include_path)

      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      local worktree_path = vim.fn.getcwd()
      assert.is_not_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extra"))
      assert.is_nil(vim.loop.fs_stat(worktree_path .. "/definitely-not-there.txt"))
    end)

    it("does nothing when .worktreeinclude is absent", function()
      -- include_path is not created here
      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      local worktree_path = vim.fn.getcwd()
      assert.is_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extra"))
    end)

    it("ignores absolute and parent-traversal paths", function()
      vim.fn.writefile({
        "/etc/hosts",
        "../escape.txt",
        ".worktree-extra",
      }, include_path)

      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      local worktree_path = vim.fn.getcwd()
      assert.is_not_nil(vim.loop.fs_stat(worktree_path .. "/.worktree-extra"))
      assert.is_nil(vim.loop.fs_stat(worktree_path .. "/etc/hosts"))
    end)
  end)

  describe("worktree_dir with absolute path", function()
    local test_branch = "test/abs-path"
    -- Resolve /tmp through fs_realpath because macOS symlinks /tmp -> /private/tmp,
    -- and getcwd() returns the realpath form after `cd`.
    local tmp_real = vim.loop.fs_realpath("/tmp") or "/tmp"
    local abs_base = tmp_real .. "/git_worktree_abs_test_" .. tostring(vim.fn.getpid())
    local created_path

    before_each(function()
      created_path = nil
      vim.fn.delete(abs_base, "rf")
      git_worktree.setup({
        cleanup_buffers = true,
        warn_unsaved = true,
        update_buffers = true,
        worktree_dir = abs_base,
      })
    end)

    after_each(function()
      vim.cmd("cd " .. original_cwd)
      if created_path then
        vim.fn.system("git worktree remove --force " .. created_path)
      end
      vim.fn.system("git branch -D " .. test_branch)
      vim.fn.delete(abs_base, "rf")
      git_worktree.setup({
        cleanup_buffers = true,
        warn_unsaved = true,
        update_buffers = true,
        worktree_dir = ".worktrees",
      })
    end)

    it("creates worktree under absolute base, namespaced by repo", function()
      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      created_path = vim.fn.getcwd()
      assert.is_truthy(
        created_path:find("^" .. vim.pesc(abs_base) .. "/"),
        "worktree path " .. created_path .. " should be under " .. abs_base
      )
      -- Branch slashes become underscores in the directory leaf
      assert.is_truthy(
        created_path:match("/test_abs%-path$"),
        "worktree leaf should be slashified branch name, got: " .. created_path
      )
      -- One namespace level should exist between abs_base and the branch leaf
      local relative = created_path:sub(#abs_base + 2)
      assert.is_truthy(
        relative:match("^[^/]+/test_abs%-path$"),
        "expected <repo>/<branch> layout, got: " .. relative
      )
    end)
  end)

  describe("worktree_dir with ~ expansion", function()
    local test_branch = "test/abs-tilde"
    local pid = tostring(vim.fn.getpid())
    local rel_home = ".git_worktree_test_tilde_" .. pid
    local home_dir = vim.fn.expand("~/" .. rel_home)
    local created_path

    before_each(function()
      created_path = nil
      vim.fn.delete(home_dir, "rf")
      git_worktree.setup({
        cleanup_buffers = true,
        warn_unsaved = true,
        update_buffers = true,
        worktree_dir = "~/" .. rel_home,
      })
    end)

    after_each(function()
      vim.cmd("cd " .. original_cwd)
      if created_path then
        vim.fn.system("git worktree remove --force " .. created_path)
      end
      vim.fn.system("git branch -D " .. test_branch)
      vim.fn.delete(home_dir, "rf")
      git_worktree.setup({
        cleanup_buffers = true,
        warn_unsaved = true,
        update_buffers = true,
        worktree_dir = ".worktrees",
      })
    end)

    it("expands ~ in worktree_dir", function()
      local success, err = git_worktree.create_worktree(test_branch, {})
      assert.is_true(success, err)

      created_path = vim.fn.getcwd()
      assert.is_truthy(
        created_path:find("^" .. vim.pesc(home_dir) .. "/"),
        "worktree path " .. created_path .. " should be under " .. home_dir
      )
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
