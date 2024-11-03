defmodule FtTuring do
  @moduledoc """
  Documentation for `FtTuring`.
  """

  alias FtTuring.{ArgsUtils, Config, ConfigParser}

  def main(args) do
    case ArgsUtils.parse_args(args) do
      %{help: true} -> ArgsUtils.print_usage()
      %{jsonfile: jsonfile, input: input} -> run(jsonfile, input)
    end
  end

  defp run(jsonfile, input) do
    IO.puts("jsonfile: #{jsonfile}, input: #{input}")

    with {:ok, config} <- ConfigParser.run(jsonfile) do
      Config.print(config)

      do_run(config, input)
    end
  end

  defp do_run(config, input) do
    state = config.initial

    tape =
      input
      |> String.graphemes()
      |> Enum.with_index()
      |> Map.new(fn {char, index} -> {index, char} end)

    params = %{config: config, tape: tape, index: 0, state: state}
    next(params)
  end

  defp next(params) do
    %{config: config, index: index, state: state, tape: tape} = params

    if state in config.finals do
      tape
    else
      current_char = Map.fetch!(tape, index)

      transition =
        config.transitions
        |> Map.fetch!(state)
        |> Enum.find(fn transition -> transition.read == current_char end)

      print_logic(%{
        tape: tape,
        index: index,
        state: state,
        char: current_char,
        transition: transition
      })

      next_params = %{
        config: config,
        index: move_index(index, transition.action),
        state: transition.to_state,
        tape: Map.put(tape, index, transition.write)
      }

      next(next_params)
    end
  end

  defp move_index(index, "RIGHT" = _action), do: index + 1
  defp move_index(index, "LEFT" = _action), do: index - 1

  defp print_logic(params) do
    %{tape: tape, index: index, state: state, char: char, transition: transition} = params

    IO.puts(
      "[#{tape_to_string(tape, index)}] (#{state}, #{char}) -> (#{transition.to_state}, #{transition.write}, #{transition.action})"
    )
  end

  defp tape_to_string(tape, index) do
    tape
    |> Enum.sort()
    |> Enum.map(fn {i, char} -> if i == index, do: "<#{char}>", else: char end)
    |> Enum.join("")
  end
end
