defmodule FtTuring.Config do
  defstruct name: nil,
            alphabet: nil,
            blank: nil,
            states: nil,
            initial: nil,
            finals: nil,
            transitions: nil

  def print(config) do
    IO.puts("""
    ********************************************************************************
    * #{config.name}
    ********************************************************************************
    Alphabet: [ #{Enum.join(config.alphabet, ", ")} ]
    States : [ #{Enum.join(config.states, ", ")} ]
    Initial : #{config.initial}
    Finals : [ #{Enum.join(config.finals, ", ")} ]
    #{Enum.map_join(config.transitions, "", fn {state, transitions} -> """
      #{Enum.map_join(transitions, "\n", fn transition -> "(#{state}, #{transition.read}) -> (#{transition.to_state}, #{transition.write}, #{transition.action})" end)}
      """ end)}
    ********************************************************************************
    """)
  end
end
