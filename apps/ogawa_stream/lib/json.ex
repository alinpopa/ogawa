defmodule OgawaStream.Json do
  defmodule Decoder do
    def decode(data) when is_binary(data) do
      data = String.trim(data)

      case Poison.decode(data) do
        {:ok, data} when is_map(data) -> data
        {:ok, data} -> %{"error" => "Invalid data", "orig" => data}
        {:error, reason} -> %{"error" => "#{inspect(reason)}", "orig" => data}
      end
    end
  end

  defmodule Encoder do
    def encode(data) when is_map(data) do
      case Poison.encode(data) do
        {:ok, value} -> value
        {:error, reason} -> Poison.encode(%{error: reason})
      end
    end
  end
end
