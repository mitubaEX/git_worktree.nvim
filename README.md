# git_worktree.nvim

A Neovim plugin for managing Git worktrees.

## Installation

```lua
-- Lazy.nvim
{
  'yourusername/git_worktree.nvim',
  config = function()
    require('git_worktree').setup()
  end
}

-- Packer
use 'yourusername/git_worktree.nvim'
```

## Commands

| Command | Description |
|---------|-------------|
| `:GitWorktreeCreate <branch>` | Create worktree for branch |
| `:GitWorktreeSwitch <branch>` | Switch to branch worktree |
| `:GitWorktreeDelete <branch>` | Delete branch worktree |
| `:GitWorktreeList` | List all worktrees |
| `:GitWorktreeCurrent` | Show current branch/worktree |

## Usage

```vim
:GitWorktreeCreate feature/new-ui    " Create worktree
:GitWorktreeSwitch feature/new-ui    " Switch to it
:GitWorktreeSwitch main              " Switch back to main
:GitWorktreeDelete feature/new-ui    " Clean up
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

## Requirements

- Neovim 0.7+
- Git

## Development

Plugin structure:
- `lua/git_worktree/init.lua` - Core functionality
- `plugin/git_worktree.lua` - Command definitions

## License

MIT