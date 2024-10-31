defmodule FtTuring do
  @moduledoc """
  Documentation for `FtTuring`.
  """

  alias FtTuring.ArgsUtils

  def main(args) do
    case ArgsUtils.parse_args(args) do
      %{help: true} -> ArgsUtils.print_usage()
      %{jsonfile: jsonfile, input: input} -> IO.puts("jsonfile: #{jsonfile}, input: #{input}")
    end
  end
end
