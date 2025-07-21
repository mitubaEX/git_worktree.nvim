# git_worktree.nvim

A Neovim plugin for managing Git worktrees directly from your editor.

This plugin provides commands to create, switch, and delete Git worktrees directly from Neovim. It simplifies the workflow of managing multiple branches in a Git repository by allowing you to work on different branches in separate directories.

## Features

- Create a new worktree for a specific branch
- Switch to an existing worktree
- Delete a worktree
- List all worktrees in the current repository
- Show current branch and worktree information
- Automatic branch name validation and sanitization
- Comprehensive error handling

## Requirements

- Neovim 0.7+
- Git installed and available in PATH

## Installation

### Packer

```lua
use 'yourusername/git_worktree.nvim'
```

### Lazy.nvim

```lua
{
  'yourusername/git_worktree.nvim',
  config = function()
    require('git_worktree').setup()
  end
}
```

### vim-plug

```vim
Plug 'yourusername/git_worktree.nvim'
```

## Setup

Add this to your Neovim configuration:

```lua
require('git_worktree').setup()
```

The setup function is optional but recommended as it validates that Git is available.

## Commands

### `:GitWorktreeCreate <branch>`
Create a new worktree for the specified branch.

**Example:**
```
:GitWorktreeCreate feature/new-ui
```

**Behavior:**
- Creates a worktree directory at `<repo_root>_<branch_name>`
- Branch names with slashes (e.g., `feature/ui`) become `feature_ui` in the directory name
- If the branch doesn't exist, Git will create it
- Validates branch name for invalid characters

### `:GitWorktreeSwitch <branch>`
Switch to an existing worktree.

**Example:**
```
:GitWorktreeSwitch main
```

**Behavior:**
- Changes Neovim's working directory to the worktree location
- Checks if the worktree directory exists before switching
- Updates all file paths and buffers to the new location

### `:GitWorktreeDelete <branch>`
Delete a worktree for the specified branch.

**Example:**
```
:GitWorktreeDelete feature/old-feature
```

**Behavior:**
- Removes the worktree directory and updates Git's worktree list
- Cannot delete the currently active worktree
- Permanently removes the directory and all uncommitted changes

### `:GitWorktreeList`
List all worktrees in the current repository.

**Example output:**
```
Git worktrees:
/path/to/repo          abc1234 [main]
/path/to/repo_feature  def5678 [feature/ui]
```

### `:GitWorktreeCurrent`
Show information about the current branch and worktree.

**Example output:**
```
Current branch: main
Current worktree: /path/to/repo
```

## How It Works

### Worktree Directory Structure

The plugin creates worktrees adjacent to your main repository:

```
project/
├── my-repo/           # Main repository
├── my-repo_main/      # Main branch worktree
├── my-repo_feature_ui/# Feature branch worktree
└── my-repo_hotfix/    # Hotfix branch worktree
```

### Branch Name Sanitization

Branch names are sanitized for filesystem compatibility:
- `feature/ui-update` → `feature_ui-update`
- `hotfix/critical-bug` → `hotfix_critical-bug`

### Validation Rules

Branch names must:
- Not be empty
- Only contain letters, numbers, hyphens, dots, underscores, and forward slashes
- Invalid characters like spaces, @, #, etc. are rejected

## Common Workflows

### Working on a New Feature

1. Create and switch to a feature branch worktree:
```
:GitWorktreeCreate feature/awesome-feature
:GitWorktreeSwitch feature/awesome-feature
```

2. Work on your feature in the separate directory
3. When done, switch back to main and clean up:
```
:GitWorktreeSwitch main
:GitWorktreeDelete feature/awesome-feature
```

### Parallel Development

1. Keep main branch open in one Neovim instance
2. Create worktrees for different features:
```
:GitWorktreeCreate feature/ui-improvements
:GitWorktreeCreate hotfix/critical-bug
```

3. Open separate Neovim instances for each worktree
4. Work on multiple branches simultaneously without conflicts

### Code Review Workflow

1. Create a worktree for the branch under review:
```
:GitWorktreeCreate review/pr-123
```

2. Switch to review the code:
```
:GitWorktreeSwitch review/pr-123
```

3. Test and review without affecting your main work
4. Delete when review is complete:
```
:GitWorktreeDelete review/pr-123
```

## Error Handling

The plugin provides clear error messages for common issues:

- **"Not in a git repository"**: Run commands from within a Git repository
- **"Branch name cannot be empty"**: Provide a valid branch name
- **"Branch name contains invalid characters"**: Use only allowed characters
- **"Worktree for branch 'X' does not exist"**: Create the worktree first or check the branch name
- **"Failed to create worktree"**: Check if branch exists or if there are permission issues

## Development Guide

### Plugin Architecture

The plugin consists of two main files:

- `lua/git_worktree/init.lua`: Core functionality and API
- `plugin/git_worktree.lua`: Neovim command definitions

### Core Functions

#### `execute_command(cmd)`
Executes shell commands and returns results with error handling.

#### `get_git_root()`
Finds the Git repository root using `git rev-parse --show-toplevel`.

#### `validate_branch_name(branch)`
Validates branch names according to plugin rules.

#### `get_worktree_path(branch)`
Generates filesystem-safe worktree paths from branch names.

### Adding New Features

1. Add new functions to `lua/git_worktree/init.lua`
2. Create corresponding commands in `plugin/git_worktree.lua`
3. Follow existing patterns for error handling and validation

### Testing

To test the plugin locally:

1. Clone this repository to your Neovim config directory
2. Add it to your plugin manager or load it manually
3. Test in a Git repository with multiple branches

### Code Style

- Use descriptive function and variable names
- Include error handling for all Git operations
- Return success/error tuples: `return success, error_message`
- Print user-friendly messages for successful operations
- Validate all user input

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request with a clear description

## Troubleshooting

### Common Issues

**Commands not working:**
- Ensure you're in a Git repository
- Check that Git is installed and in PATH
- Verify the plugin is properly loaded

**Worktree creation fails:**
- Check if the branch exists or can be created
- Ensure you have write permissions in the parent directory
- Verify no conflicts with existing directories

**Switch command not working:**
- Ensure the worktree was created successfully
- Check that the target directory exists
- Verify Neovim has permissions to change directories

### Debug Mode

For debugging, you can manually test Git commands:

```bash
# Test if Git is available
git --version

# Test worktree commands
git worktree list
git worktree add ../repo_feature feature
```

## License

MIT License - see LICENSE file for details.
