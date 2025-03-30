defmodule WriteUTM do
  defp input_states, do: ["A", "B", "C", "D", "E"]
  defp input_alphabet, do: ["1", "+", "=", "."]
  defp cursor, do: "_"
  defp input_separator, do: "|"
  defp input_blank, do: "."
  # This won't be used?
  defp blank, do: "!"
  defp input_actions, do: ["R", "L"]

  # input is composed of 7 parts, separated by input_separator
  # 1. alphabet
  # 2. blank
  # 3. states
  # 4. initial state
  # 5. final states
  # 6. transitions
  # 7. input

  defp possible_symbols(parts) do
    parts = if length(parts) == 1, do: parts, else: [:separator | parts]

    parts
    |> Enum.map(fn
      part when part in [:alphabet, :states, :separator] -> part
      part when part in [:initial, :finals] -> :states
      :transitions -> [:alphabet, :states, :actions]
      :input -> [:alphabet, :cursor]
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn
      :alphabet -> input_alphabet()
      :states -> input_states()
      :separator -> input_separator()
      :actions -> input_actions()
      :cursor -> cursor()
    end)
    |> List.flatten()
  end

  defp alphabet do
    List.flatten([
      input_states(),
      input_alphabet(),
      cursor(),
      input_separator(),
      input_blank(),
      blank(),
      input_actions()
    ])
  end

  # number of symbols and number of states are unknown
  def run(output: output) do
    transitions = build_transitions()
    final_state = "HALT"
    states = [final_state | Map.keys(transitions)]

    description = %{
      name: "universal turing machine",
      alphabet: alphabet(),
      blank: blank(),
      states: states,
      initial: "find_initial_state_1",
      finals: [final_state],
      transitions: transitions
    }

    if output == :console do
      IO.inspect(description)
    else
      description
      |> Jason.encode!(pretty: true)
      |> then(&File.write!(output, &1))
    end
  end

  # INPUT: "1.+=|.|ABCD|A|D|A1A1RA+A+RA=B.LB1C.LB+E.LC1C1LC1D1L|_11+1111="
  defp build_transitions do
    build_find_initial_state_transitions()
    |> Map.merge(build_find_cursor_transitions())
    |> Map.merge(build_read_current_symbol_transitions())
    |> Map.merge(build_check_finals_transitions())
    |> Map.merge(build_find_next_separator_transitions())
    |> Map.merge(build_find_transition_transitions())
    |> Map.merge(build_read_transition_transitions())
    |> Map.merge(build_execute_transitions())
  end

  defp build_find_initial_state_transitions do
    # Read three input_separators and the next one is the state
    input_separator_num = 3

    move_symbols = possible_symbols([:alphabet, :states]) -- [input_separator()]

    step_1_and_2_and_3 =
      for step <- 1..input_separator_num do
        move =
          for symbol <- move_symbols,
              do: %{
                read: symbol,
                to_state: "find_initial_state_#{step}",
                write: symbol,
                action: "RIGHT"
              }

        read_input_separator = %{
          read: input_separator(),
          to_state: "find_initial_state_#{step + 1}",
          write: input_separator(),
          action: "RIGHT"
        }

        {"find_initial_state_#{step}", [read_input_separator | move]}
      end
      |> Map.new()

    step_4_transitions =
      Enum.map(input_states(), fn state ->
        %{
          read: state,
          to_state: "find_cursor_#{state}",
          write: state,
          action: "RIGHT"
        }
      end)

    step_4 = %{"find_initial_state_#{input_separator_num + 1}" => step_4_transitions}

    Map.merge(step_1_and_2_and_3, step_4)
  end

  defp build_find_cursor_transitions do
    Enum.map(input_states(), fn state ->
      move =
        Enum.map(possible_symbols([:finals, :states, :transitions]), fn symbol ->
          %{
            read: symbol,
            to_state: "find_cursor_#{state}",
            write: symbol,
            action: "RIGHT"
          }
        end)

      read_cursor = %{
        read: cursor(),
        to_state: "read_current_symbol_#{state}",
        write: cursor(),
        action: "RIGHT"
      }

      {"find_cursor_#{state}", [read_cursor | move]}
    end)
    |> Map.new()
  end

  defp build_read_current_symbol_transitions do
    input_states()
    |> Enum.map(fn state ->
      read_symbol =
        Enum.map(input_alphabet(), fn symbol ->
          %{
            read: symbol,
            to_state: "check_finals_1_#{state}_#{symbol}",
            write: symbol,
            action: "LEFT"
          }
        end)

      {"read_current_symbol_#{state}", read_symbol}
    end)
    |> Map.new()
  end

  defp build_check_finals_transitions do
    # Read two input_separators
    move_symbols = possible_symbols([:transitions, :input]) -- [input_separator()]

    step_1_and_2 =
      for step <- 1..2, state <- input_states(), symbol <- input_alphabet() do
        current_state = "check_finals_#{step}_#{state}_#{symbol}"

        move =
          Enum.map(move_symbols, fn read_symbol ->
            %{
              read: read_symbol,
              to_state: current_state,
              write: read_symbol,
              action: "LEFT"
            }
          end)

        read_input_separator = %{
          read: input_separator(),
          to_state: "check_finals_#{step + 1}_#{state}_#{symbol}",
          write: input_separator(),
          action: "LEFT"
        }

        {current_state, [read_input_separator | move]}
      end
      |> Map.new()

    step_3 =
      for state <- input_states(), symbol <- input_alphabet() do
        current_state = "check_finals_3_#{state}_#{symbol}"

        finish = %{
          read: state,
          to_state: "HALT",
          write: state,
          action: "RIGHT"
        }

        move_symbols = possible_symbols([:finals]) -- [state]

        read_other_states =
          Enum.map(move_symbols, fn other_state ->
            %{
              read: other_state,
              to_state: current_state,
              write: other_state,
              action: "LEFT"
            }
          end)

        read_input_separator = %{
          read: input_separator(),
          to_state: "find_next_input_separator_#{state}_#{symbol}",
          write: input_separator(),
          action: "RIGHT"
        }

        {current_state, [read_input_separator, finish | read_other_states]}
      end
      |> Map.new()

    Map.merge(step_1_and_2, step_3)
  end

  defp build_find_next_separator_transitions do
    for state <- input_states(), symbol <- input_alphabet() do
      current_state = "find_next_input_separator_#{state}_#{symbol}"

      read_input_separator = %{
        read: input_separator(),
        to_state: "find_transition_1_#{state}_#{symbol}",
        write: input_separator(),
        action: "RIGHT"
      }

      read_other =
        Enum.map(possible_symbols([:finals]), fn read_symbol ->
          %{
            read: read_symbol,
            to_state: current_state,
            write: read_symbol,
            action: "RIGHT"
          }
        end)

      {current_state, [read_input_separator | read_other]}
    end
    |> Map.new()
  end

  defp build_find_transition_transitions do
    # Check if it's matching state
    step_1 =
      for state <- input_states(), symbol <- input_alphabet() do
        current_state = "find_transition_1_#{state}_#{symbol}"

        move_symbols = possible_symbols([:transitions]) -- [state]

        other_states =
          Enum.map(move_symbols, fn read_symbol ->
            %{
              read: read_symbol,
              to_state: "find_transition_3_#{state}_#{symbol}",
              write: read_symbol,
              action: "RIGHT"
            }
          end)

        matching_state = %{
          read: state,
          to_state: "find_transition_2_#{state}_#{symbol}",
          write: state,
          action: "RIGHT"
        }

        {current_state, [matching_state | other_states]}
      end
      |> Map.new()

    # Check if it's matching symbol
    step_2 =
      for state <- input_states(), symbol <- input_alphabet() do
        move_symbols = possible_symbols([:transitions]) -- [symbol]

        other_symbols =
          Enum.map(move_symbols, fn read_symbol ->
            %{
              read: read_symbol,
              to_state: "find_transition_4_#{state}_#{symbol}",
              write: read_symbol,
              action: "RIGHT"
            }
          end)

        matching_symbol = %{
          read: symbol,
          to_state: "read_transition_1",
          write: symbol,
          action: "RIGHT"
        }

        {"find_transition_2_#{state}_#{symbol}", [matching_symbol | other_symbols]}
      end
      |> Map.new()

    possible_symbols = possible_symbols([:transitions]) ++ [input_separator()]

    step_3_and_4_and_5_and_6 =
      for step <- 3..6, state <- input_states(), symbol <- input_alphabet() do
        move =
          Enum.map(possible_symbols, fn read_symbol ->
            to_state =
              if step == 6,
                do: "find_transition_1_#{state}_#{symbol}",
                else: "find_transition_#{step + 1}_#{state}_#{symbol}"

            %{
              read: read_symbol,
              to_state: to_state,
              write: read_symbol,
              action: "RIGHT"
            }
          end)

        {"find_transition_#{step}_#{state}_#{symbol}", move}
      end
      |> Map.new()

    step_1
    |> Map.merge(step_2)
    |> Map.merge(step_3_and_4_and_5_and_6)
  end

  defp build_read_transition_transitions do
    step_1 = %{
      "read_transition_1" =>
        Enum.map(input_states(), fn state ->
          %{
            read: state,
            to_state: "read_transition_2_#{state}",
            write: state,
            action: "RIGHT"
          }
        end)
    }

    step_2 =
      input_states()
      |> Enum.map(fn state ->
        read_to_write =
          Enum.map(input_alphabet(), fn symbol ->
            %{
              read: symbol,
              to_state: "read_transition_3_#{state}_#{symbol}",
              write: symbol,
              action: "RIGHT"
            }
          end)

        {"read_transition_2_#{state}", read_to_write}
      end)
      |> Map.new()

    # Read action
    step_3 =
      for state <- input_states(), symbol <- input_alphabet() do
        read_action =
          Enum.map(input_actions(), fn action ->
            %{
              read: action,
              to_state: "execute_1_#{state}_#{symbol}_#{action}",
              write: action,
              action: "RIGHT"
            }
          end)

        {"read_transition_3_#{state}_#{symbol}", read_action}
      end
      |> Map.new()

    step_1
    |> Map.merge(step_2)
    |> Map.merge(step_3)
  end

  defp build_execute_transitions do
    # Read until cursor
    step_1 =
      for state <- input_states(), symbol <- input_alphabet(), action <- input_actions() do
        move_symbols = possible_symbols([:transitions, :input]) -- [cursor()]

        move =
          Enum.map(move_symbols, fn read_symbol ->
            %{
              read: read_symbol,
              to_state: "execute_1_#{state}_#{symbol}_#{action}",
              write: read_symbol,
              action: "RIGHT"
            }
          end)

        read_cursor = %{
          read: cursor(),
          to_state: "execute_2_#{state}_#{symbol}_#{action}",
          write: cursor(),
          action: "RIGHT"
        }

        {"execute_1_#{state}_#{symbol}_#{action}", [read_cursor | move]}
      end
      |> Map.new()

    # 1_1+1111="
    # R: 1?_+1111="
    step_2_right =
      for state <- input_states(), write_symbol <- input_alphabet() do
        read =
          Enum.map(input_alphabet(), fn read_symbol ->
            %{
              read: read_symbol,
              to_state: "execute_3_#{state}_#{write_symbol}_R",
              write: cursor(),
              action: "LEFT"
            }
          end)

        {"execute_2_#{state}_#{write_symbol}_R", read}
      end
      |> Map.new()

    step_3_right =
      for state <- input_states(), symbol <- input_alphabet() do
        write =
          %{
            read: cursor(),
            to_state: "find_cursor_#{state}",
            write: symbol,
            action: "RIGHT"
          }

        {"execute_3_#{state}_#{symbol}_R", [write]}
      end
      |> Map.new()

    # 1_1+1111="
    # L: _1?+1111="
    step_2_left =
      for state <- input_states(), write_symbol <- input_alphabet() do
        read =
          Enum.map(input_alphabet(), fn read_symbol ->
            %{
              read: read_symbol,
              to_state: "execute_3_#{state}_L",
              write: write_symbol,
              action: "LEFT"
            }
          end)

        {"execute_2_#{state}_#{write_symbol}_L", read}
      end
      |> Map.new()

    step_3_left =
      for state <- input_states() do
        current_state = "execute_3_#{state}_L"

        read =
          %{
            read: cursor(),
            to_state: "execute_4_#{state}",
            write: cursor(),
            action: "LEFT"
          }

        {current_state, [read]}
      end
      |> Map.new()

    step_4 =
      for state <- input_states() do
        read =
          Enum.map(input_alphabet(), fn symbol ->
            %{
              read: symbol,
              to_state: "execute_5_#{state}_#{symbol}",
              write: cursor(),
              action: "RIGHT"
            }
          end)

        {"execute_4_#{state}", read}
      end
      |> Map.new()

    step_5 =
      for state <- input_states(), symbol <- input_alphabet() do
        write = %{
          read: cursor(),
          to_state: "find_cursor_#{state}",
          write: symbol,
          action: "LEFT"
        }

        {"execute_5_#{state}_#{symbol}", [write]}
      end
      |> Map.new()

    step_1
    |> Map.merge(step_2_right)
    |> Map.merge(step_3_right)
    |> Map.merge(step_2_left)
    |> Map.merge(step_3_left)
    |> Map.merge(step_4)
    |> Map.merge(step_5)
  end

  def write_input do
    input_separator = "|"
    characters = "1.+="
    blank = "."
    states = "ABCD"
    initial = "A"
    finals = "D"

    transitions = [
      [
        "A1A1R",
        "A+A+R",
        "A=B.L"
      ],
      [
        "B1C.L",
        "B+E.L"
      ],
      [
        "C1C1L",
        "C+D1L"
      ]
    ]

    input = "_11+1111="

    Enum.join([characters, blank, states, initial, finals, transitions, input], input_separator)
  end
end

filename = "machine_descriptions/utm.json"

WriteUTM.run(output: :console)
WriteUTM.run(output: filename)
