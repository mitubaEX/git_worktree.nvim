# git_worktree.nvim

A Neovim plugin for managing Git worktrees with Telescope integration.

## Installation

```lua
-- Lazy.nvim
{
  'yourusername/git_worktree.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('git_worktree').setup({
      cleanup_buffers = true,  -- Clean up old buffers when switching
      warn_unsaved = true,     -- Warn about unsaved changes
      update_buffers = true,   -- Update buffer paths to new worktree
      copy_envrc = true,       -- Copy .envrc file to new worktrees (direnv)
    })
    require('telescope').load_extension('git_worktree')
  end
}

-- Packer
use {
  'yourusername/git_worktree.nvim',
  requires = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('telescope').load_extension('git_worktree')
  end
}
```

## Commands

### CLI Commands
| Command | Description |
|---------|-------------|
| `:GitWorktreeCreate <branch>` | Create worktree (and branch if needed) |
| `:GitWorktreeSwitch <branch>` | Switch to branch worktree |
| `:GitWorktreeDelete <branch>` | Delete branch worktree |
| `:GitWorktreeList` | List all worktrees |
| `:GitWorktreeCurrent` | Show current branch/worktree |
| `:GitWorktreeReview <pr_number>` | Create worktree for GitHub PR review |
| `:GitWorktreeCleanup` | Remove all worktrees except current |

### Telescope Commands
| Command | Description |
|---------|-------------|
| `:Telescope git_worktree` | Interactive worktree picker |
| `:Telescope git_worktree create` | Create worktree from branch list |

## Usage

### CLI
```vim
:GitWorktreeCreate feature/new-ui    " Create worktree
:GitWorktreeSwitch feature/new-ui    " Switch to it
:GitWorktreeSwitch main              " Switch back to main
:GitWorktreeDelete feature/new-ui    " Clean up
:GitWorktreeReview 123               " Review GitHub PR #123
:GitWorktreeCleanup                  " Clean up all worktrees
```

### Telescope
```vim
:Telescope git_worktree              " Interactive picker
" <Enter> - Switch to worktree
" <C-d>   - Delete worktree (not current)
" <C-n>   - Create new worktree

:Telescope git_worktree create       " Create from branches
```

### Keybindings
```lua
-- Optional keybindings
vim.keymap.set('n', '<leader>gw', '<cmd>Telescope git_worktree<cr>')
vim.keymap.set('n', '<leader>gW', '<cmd>Telescope git_worktree create<cr>')
```

## How It Works

Creates worktrees in adjacent directories:

```
project/
├── my-repo/              # Main repository
├── my-repo_feature_ui/   # Feature branch worktree
└── my-repo_hotfix/       # Hotfix branch worktree
```

Branch names with slashes become underscores in directory names.

## Configuration

```lua
require('git_worktree').setup({
  cleanup_buffers = true,  -- Clean up old buffers when switching
  warn_unsaved = true,     -- Warn about unsaved changes in buffers
  update_buffers = true,   -- Update buffer paths to match new worktree
  copy_envrc = true,       -- Copy .envrc file to new worktrees (direnv)
})
```

**Buffer Management:**
- **`update_buffers = true`**: Automatically updates open buffers to point to the same files in the new worktree
- **`cleanup_buffers = true`**: Closes buffers that don't exist in the new worktree
- **Smart handling**: Preserves unsaved changes and shows warnings

**Direnv Integration:**
- **`copy_envrc = true`**: Automatically copies `.envrc` file from current worktree to new worktrees
- **Smart copying**: Won't overwrite existing `.envrc` files in target worktree
- **Seamless workflow**: Environment variables follow you to new worktrees

**Example:** If you have `A/init.lua` open and switch worktrees, the buffer automatically updates to point to the same file in the new worktree location.

## Smart Branch Handling

The plugin automatically handles different branch scenarios:

- **Existing local branch**: Creates worktree from the local branch
- **Existing remote branch**: Creates local branch tracking the remote and creates worktree
- **New branch**: Creates both the branch and worktree from current HEAD

```vim
:GitWorktreeCreate feature/new-ui    " Creates branch + worktree if branch doesn't exist
:GitWorktreeCreate existing-branch   " Uses existing branch for worktree
:GitWorktreeCreate origin-branch     " Creates local branch tracking remote + worktree
```

## GitHub PR Review

The `:GitWorktreeReview` command streamlines code review by automatically:

1. **Fetching PR information** using GitHub CLI
2. **Creating a dedicated review worktree** with branch name `review/pr-<number>`
3. **Handling forks** by adding remote and fetching the PR branch
4. **Switching to the review worktree** automatically

```vim
:GitWorktreeReview 123    " Reviews PR #123
```

**Requirements for PR review:**
- GitHub CLI (`gh`) installed and authenticated
- Repository must have GitHub origin remote

## Bulk Cleanup

The `:GitWorktreeCleanup` command helps you clean up all worktrees at once:

1. **Lists all worktrees** except the current one
2. **Shows confirmation prompt** with details of what will be deleted
3. **Safely removes worktrees** one by one
4. **Reports results** including any failures

```vim
:GitWorktreeCleanup
```

**Example output:**
```
The following worktrees will be deleted:
  - feature/ui-update (/repo_feature_ui-update)  
  - review/pr-123 (/repo_review_pr-123)
  - hotfix/bug (/repo_hotfix_bug)

Delete 3 worktree(s)? (y/N): y

Deleting worktrees...
Deleted worktree: feature/ui-update
Deleted worktree: review/pr-123  
Failed to delete hotfix/bug: worktree contains modified or untracked files

Cleanup completed:
  - 2 worktrees deleted
  - 1 worktrees failed to delete

Tip: Use 'git worktree remove --force <path>' to force delete
```

## Requirements

- Neovim 0.7+
- Git
- telescope.nvim (for UI)
- direnv (optional, for `.envrc` file support)
- GitHub CLI (`gh`) (optional, for PR review feature)

## Development

Plugin structure:
- `lua/git_worktree/init.lua` - Core functionality
- `plugin/git_worktree.lua` - Command definitions
- `lua/telescope/_extensions/git_worktree.lua` - Telescope integration

## License

MIT