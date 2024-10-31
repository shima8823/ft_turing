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

    with {:ok, parsed_config} <- ConfigParser.run(jsonfile) do
      Config.print(parsed_config)
    end
  end
end
