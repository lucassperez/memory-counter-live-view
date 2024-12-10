.DEFAULT_GOAL := up

# Start iex server ready to be connected by another iex (distributed erlang mode)
distributed.server:
	iex --sname memory_counter -S mix phx.server

# Connects to running server in distributed mode (started with distributed.server)
distributed.connect:
	iex --sname console --remsh memory_counter@$(shell hostname)

# Start bash inside docker container
bash:
	docker compose run --service-ports app bash

# Starts server inside docker container
up:
	docker compose up

# Shows this help message
help:
	@printf "\n\033[1;33mIn Memory Counters\n------------------\n\033[0m"
	@awk '/^[a-zA-Z\-_0-9\.%]+:/ { \
		if (match($$0, /^[a-z].*:/)) { \
			helpCommand = substr($$1, 0, index($$1, ":") - 1); \
			hasHelpMessage = match(lastLine, /^# (.*)/); \
			if (hasHelpMessage) { \
				helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
				printf "\033[1;32mmake %s:\033[0m %s\n", helpCommand, helpMessage; \
			} else { \
				printf "\033[1;32mmake %s\033[0m\n", helpCommand; \
			} \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST) | sort
	@printf "\n"
