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

## Requirements

- Neovim 0.7+
- Git
- telescope.nvim (for UI)
- direnv (optional, for `.envrc` file support)

## Development

Plugin structure:
- `lua/git_worktree/init.lua` - Core functionality
- `plugin/git_worktree.lua` - Command definitions
- `lua/telescope/_extensions/git_worktree.lua` - Telescope integration

## License

MIT