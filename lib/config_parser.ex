defmodule FtTuring.ConfigParser do
  import FtTuring.Utils, only: [validate: 2]

  @keys [:name, :alphabet, :blank, :states, :initial, :finals, :transitions]
  @transition_keys [:read, :to_state, :write, :action]
  def run(jsonfile) do
    with {:ok, json} <- File.read(jsonfile),
         {:ok, config} <- Jason.decode(json),
         parsed_config = keys_to_allowed_atoms(config, @keys),
         :ok <- validate(required_keys_exist?(parsed_config, @keys), :missing_key),
         {:ok, transitions} <- parse_transitions(parsed_config.transitions) do
      parsed_config = Map.put(parsed_config, :transitions, transitions)

      # TODO: validate the config
      {:ok, parsed_config}
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
end
