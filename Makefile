NAME = ft_turing

.PHONY: all deps build test clean fclean re

all: deps build

deps:
	@which elixir > /dev/null 2>&1 || (echo "Error: Elixir is not installed." && \
		echo "  macOS:  brew install elixir" && \
		echo "  Ubuntu: sudo apt-get install elixir" && \
		echo "  Other:  https://elixir-lang.org/install.html" && exit 1)
	@mix local.hex --force --if-missing
	@mix local.rebar --force --if-missing
	@test -d deps || mix deps.get

build:
	@mix escript.build

test:
	@mix test

clean:
	@rm -rf _build deps

fclean: clean
	@rm -f $(NAME)

re: fclean all
