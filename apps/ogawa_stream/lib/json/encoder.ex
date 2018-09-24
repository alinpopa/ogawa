defmodule OgawaStream.Json.Encoder do
  def encode(data) when is_map(data) do
    case Poison.encode(data) do
      {:ok, value} -> value
      {:error, reason} -> Poison.encode(%{error: reason})
    end
  end
end
