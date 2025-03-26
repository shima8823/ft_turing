defmodule FtTuring.ConfigParser do
  import FtTuring.Utils, only: [validate: 2]

  @keys [:name, :alphabet, :blank, :states, :initial, :finals, :transitions]
  @transition_keys [:read, :to_state, :write, :action]
  @valid_actions ["LEFT", "RIGHT"]

  def run(json_content) do
    with {:ok, config} <- decode_json(json_content),
         parsed_config = keys_to_allowed_atoms(config, @keys),
         :ok <- validate(required_keys_exist?(parsed_config, @keys), :missing_key),
         {:ok, transitions} <- parse_transitions(parsed_config.transitions),
         parsed_config = Map.put(parsed_config, :transitions, transitions),
         :ok <- validate_alphabet(parsed_config),
         :ok <- validate_states(parsed_config),
         :ok <- validate_initial_state(parsed_config),
         :ok <- validate_final_states(parsed_config),
         :ok <- validate_transitions(parsed_config) do
      {:ok, parsed_config}
    end
  end

  defp decode_json(json_content) do
    case Jason.decode(json_content) do
      {:ok, config} -> {:ok, config}
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
    end
  end

  defp parse_transitions(transitions) do
    transitions =
      transitions
      |> Enum.map(fn {key, value} ->
        {key, Enum.map(value, &keys_to_allowed_atoms(&1, @transition_keys))}
      end)
      |> Map.new()

    {:ok, transitions}
  end

  @missing_value :"missing value"
  defp keys_to_allowed_atoms(map, allowed_keys) do
    allowed_keys
    |> Map.new(&{&1, Atom.to_string(&1)})
    |> Enum.map(fn {atom_key, string_key} ->
      {atom_key,
       Map.get_lazy(map, string_key, fn ->
         Map.get(map, atom_key, @missing_value)
       end)}
    end)
    |> Enum.reject(fn
      {_, @missing_value} -> true
      _ -> false
    end)
    |> Map.new()
  end

  defp required_keys_exist?(map, required_keys) do
    Enum.all?(required_keys, &Map.has_key?(map, &1))
  end

  defp validate_alphabet(config) do
    is_valid_list = is_list(config.alphabet)
    is_not_empty = not Enum.empty?(config.alphabet)
    all_single_chars = Enum.all?(config.alphabet, &(String.length(&1) == 1))

    validate(
      is_valid_list and is_not_empty and all_single_chars,
      :invalid_alphabet
    )
  end

  defp validate_states(config) do
    is_valid_list = is_list(config.states)
    is_not_empty = not Enum.empty?(config.states)

    validate(
      is_valid_list and is_not_empty,
      :invalid_states
    )
  end

  defp validate_initial_state(config) do
    initial_state_exists = config.initial in config.states

    validate(
      initial_state_exists,
      :invalid_initial_state
    )
  end

  defp validate_final_states(config) do
    is_valid_list = is_list(config.finals)
    all_states_exist = Enum.all?(config.finals, &(&1 in config.states))

    validate(
      is_valid_list and all_states_exist,
      :invalid_final_states
    )
  end

  defp validate_transitions(config) do
    with :ok <- validate_transitions_map(config),
         :ok <- validate_transition_states(config),
         :ok <- validate_all_states_have_transitions(config) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_transitions_map(config) do
    is_valid_map = is_map(config.transitions)

    validate(
      is_valid_map,
      :invalid_transitions
    )
  end

  defp validate_transition_states(config) do
    all_states_valid =
      Enum.all?(config.transitions, fn {state, transitions} ->
        state_exists = state in config.states
        transitions_is_list = is_list(transitions)
        all_transitions_valid = Enum.all?(transitions, &valid_transition?(&1, config))

        state_exists and transitions_is_list and all_transitions_valid
      end)

    validate(
      all_states_valid,
      :invalid_transitions
    )
  end

  defp validate_all_states_have_transitions(config) do
    non_final_states = config.states -- config.finals

    all_states_have_transitions =
      Enum.all?(non_final_states, &Map.has_key?(config.transitions, &1))

    validate(
      all_states_have_transitions,
      :invalid_transitions
    )
  end

  defp valid_transition?(transition, config) do
    is_valid_map = is_map(transition)
    has_required_keys = required_keys_exist?(transition, @transition_keys)
    read_symbol_valid = transition.read in config.alphabet
    write_symbol_valid = transition.write in config.alphabet
    to_state_valid = transition.to_state in config.states
    action_valid = transition.action in @valid_actions

    is_valid_map and
      has_required_keys and
      read_symbol_valid and
      write_symbol_valid and
      to_state_valid and
      action_valid
  end
end
