defmodule FtTuring.ArgsUtils do
  def parse_args(args) do
    case args do
      ["-h" | _] -> %{help: true}
      ["--help" | _] -> %{help: true}
      [jsonfile, input] -> %{jsonfile: jsonfile, input: input}
      _ -> %{help: true}
    end
  end

  def print_usage do
    usage = """
    usage: ft_turing [-h] jsonfile input

    positional arguments:
      jsonfile      json description of the machine
      input         input of the machine

    optional arguments:
      -h, --help    show this help message and exit
    """

    IO.puts(usage)
  end
end
