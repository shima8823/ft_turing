defmodule FtTuring.Utils do
  @spec validate(boolean(), any()) :: :ok | {:error, any()}
  def validate(true, _reason), do: :ok
  def validate(false, reason), do: {:error, reason}
end
