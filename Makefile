.PHONY: test
test:
	@echo "Running tests with plenary..."
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"

.PHONY: test-watch
test-watch:
	@echo "Running tests in watch mode..."
	while true; do \
		make test; \
		inotifywait -qre close_write lua/ tests/ plugin/; \
	done

.PHONY: lint
lint:
	@echo "Running stylua..."
	stylua --check lua/ tests/ plugin/

.PHONY: format
format:
	@echo "Formatting code with stylua..."
	stylua lua/ tests/ plugin/

.PHONY: clean
clean:
	@echo "Cleaning up test artifacts..."
	@git worktree list | grep -v "$$(pwd)" | awk '{print $$1}' | xargs -r -I {} git worktree remove {} --force || true
	@git branch | grep "test/" | xargs -r git branch -D || true
