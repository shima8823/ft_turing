defmodule FtTuring.ConfigParserTest do
  use ExUnit.Case
  alias FtTuring.ConfigParser

  describe "run/1" do
    test "parses valid config" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b", "c"],
        "blank" => "b",
        "states" => ["q0", "q1", "q2"],
        "initial" => "q0",
        "finals" => ["q2"],
        "transitions" => %{
          "q0" => [
            %{"read" => "a", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ],
          "q1" => [
            %{"read" => "b", "write" => "c", "to_state" => "q2", "action" => "LEFT"}
          ]
        }
      }

      {:ok, json} = Jason.encode(config)
      {:ok, parsed} = ConfigParser.run(json)

      assert parsed.name == "test"
      assert parsed.alphabet == ["a", "b", "c"]
      assert parsed.blank == "b"
      assert parsed.states == ["q0", "q1", "q2"]
      assert parsed.initial == "q0"
      assert parsed.finals == ["q2"]
      assert map_size(parsed.transitions) == 2
    end

    test "returns error for missing required keys" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b"]
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :missing_key}
    end

    test "returns error for invalid alphabet" do
      config = %{
        "name" => "test",
        # "aa" is invalid (length > 1)
        "alphabet" => ["aa", "b"],
        "blank" => "b",
        "states" => ["q0", "q1"],
        "initial" => "q0",
        "finals" => ["q1"],
        "transitions" => %{
          "q0" => [
            %{"read" => "b", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ]
        }
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :invalid_alphabet}
    end

    test "returns error for invalid initial state" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b"],
        "blank" => "b",
        "states" => ["q0", "q1"],
        # q2 is not in states
        "initial" => "q2",
        "finals" => ["q1"],
        "transitions" => %{
          "q0" => [
            %{"read" => "b", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ]
        }
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :invalid_initial_state}
    end

    test "returns error for invalid final states" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b"],
        "blank" => "b",
        "states" => ["q0", "q1"],
        "initial" => "q0",
        # q2 is not in states
        "finals" => ["q2"],
        "transitions" => %{
          "q0" => [
            %{"read" => "b", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ]
        }
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :invalid_final_states}
    end

    test "returns error for invalid transitions" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b"],
        "blank" => "b",
        "states" => ["q0", "q1"],
        "initial" => "q0",
        "finals" => ["q1"],
        "transitions" => %{
          "q0" => [
            # "x" not in alphabet
            %{"read" => "x", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ]
        }
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :invalid_transitions}
    end

    test "returns error for missing transitions for non-final state" do
      config = %{
        "name" => "test",
        "alphabet" => ["a", "b"],
        "blank" => "b",
        "states" => ["q0", "q1", "q2"],
        "initial" => "q0",
        "finals" => ["q2"],
        "transitions" => %{
          "q0" => [
            %{"read" => "b", "write" => "b", "to_state" => "q1", "action" => "RIGHT"}
          ]
          # q1 is missing transitions
        }
      }

      {:ok, json} = Jason.encode(config)
      assert ConfigParser.run(json) == {:error, :invalid_transitions}
    end

    test "returns error for invalid JSON" do
      invalid_json = "{invalid json"
      assert ConfigParser.run(invalid_json) == {:error, :invalid_json}
    end
  end
end
