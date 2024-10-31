defmodule FtTuring.ConfigParser do
  @first_keys [:name, :alphabet, :blank, :states, :initial, :finals, :transitions]
  @transition_keys [:read, :to_state, :write, :action]
  def run(jsonfile) do
    with {:ok, json} <- File.read(jsonfile),
         {:ok, config} <- Jason.decode(json) do
      parsed_config =
        config
        |> keys_to_allowed_atoms(@first_keys)
        |> Map.update(:transitions, nil, &parse_transitions(&1))

      # TODO: validate the config
      {:ok, parsed_config}
    end
  end

  defp parse_transitions(transitions) do
    transitions
    |> Enum.map(fn {key, value} ->
      {key, Enum.map(value, &keys_to_allowed_atoms(&1, @transition_keys))}
    end)
    |> Map.new()
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
end
