# FtTuring

## How to run

```sh
mix deps.get
mix escript.build
```

```sh
./ft_turing
./ft_turing "machine_descriptions/unary_sub.json" "111-11="
```

## Test Coverage

To run tests with coverage:

```sh
mix coveralls
```

For a detailed coverage report:

```sh
mix coveralls.detail
```

For an HTML coverage report:

```sh
mix coveralls.html
```
