defmodule FtTuringTest do
  use ExUnit.Case
  doctest FtTuring

  @empty_char "."

  describe "unary_sub" do
    test "succeeds" do
      tape = FtTuring.main(["machine_descriptions/unary_sub.json", "111-11="])
      assert tape_to_string(tape) == "1......"
    end
  end

  describe "unary_add" do
    test "succeeds" do
      tape = FtTuring.main(["machine_descriptions/unary_add.json", "111+11="])
      assert tape_to_string(tape) == "111111."
    end
  end

  describe "even_zero" do
    test "prints y" do
      patterns = ["", "00", "000000"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/even_zero.json", pattern])
        assert get_right_most_non_empty_char(tape) == "y"
      end)
    end

    test "prints n" do
      patterns = ["0", "000", "000000000"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/even_zero.json", pattern])
        assert get_right_most_non_empty_char(tape) == "n"
      end)
    end
  end

  describe "zero_one" do
    test "prints y" do
      patterns = ["0011", "", "00001111", "0011"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/zero_one.json", pattern])
        assert get_right_most_non_empty_char(tape) == "y"
      end)
    end

    test "prints n" do
      patterns = ["011", "010", "110", "111", "000", "001", "100", "101"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/zero_one.json", pattern])
        assert get_right_most_non_empty_char(tape) == "n"
      end)
    end
  end

  describe "palindrome" do
    test "succeeds" do
      patterns = ["001100", "00", "1", "111", "11011"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/palindrome.json", pattern])
        assert get_right_most_non_empty_char(tape) == "y"
      end)
    end

    test "fails" do
      patterns = ["0011", "01", "111111110", "110111"]

      Enum.each(patterns, fn pattern ->
        tape = FtTuring.main(["machine_descriptions/palindrome.json", pattern])
        assert get_right_most_non_empty_char(tape) == "n"
      end)
    end
  end

  defp tape_to_string(tape) do
    tape
    |> Enum.sort()
    |> Enum.map_join("", fn {_, char} -> char end)
  end

  defp get_right_most_non_empty_char(tape) do
    {_, char} =
      tape
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.find(fn {_, char} -> char != @empty_char end)

    char
  end
end
