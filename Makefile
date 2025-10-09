.PHONY: test test-basic test-cleanup test-review clean

# Run all tests
test: test-basic test-cleanup test-review
	@echo ""
	@echo "✓ All tests passed!"

# Run basic command tests
test-basic:
	@echo "Running basic command tests..."
	@nvim --headless -u NONE \
		-c "set rtp+=." \
		-c "luafile test_commands.lua" \
		-c "qa"

# Run cleanup test
test-cleanup:
	@echo "Running cleanup test..."
	@nvim --headless -u NONE \
		-c "set rtp+=." \
		-c "luafile test_cleanup.lua" \
		-c "qa"

# Run review fix test
test-review:
	@echo "Running review fix test..."
	@nvim --headless -u NONE \
		-c "set rtp+=." \
		-c "luafile test_review_fix.lua" \
		-c "qa"

# Clean up any remaining test worktrees and branches
clean:
	@echo "Cleaning up test worktrees and branches..."
	@git worktree list | grep -v "$(shell pwd)" | awk '{print $$1}' | xargs -r -I {} git worktree remove {} --force 2>/dev/null || true
	@git branch | grep "test/" | xargs -r git branch -D 2>/dev/null || true
	@git branch | grep "feature/pr-test" | xargs -r git branch -D 2>/dev/null || true
	@echo "Cleanup completed"

# Show help
help:
	@echo "Available targets:"
	@echo "  test         - Run all tests"
	@echo "  test-basic   - Run basic command tests"
	@echo "  test-cleanup - Run cleanup test"
	@echo "  test-review  - Run review fix test"
	@echo "  clean        - Clean up test worktrees and branches"
	@echo "  help         - Show this help message"
