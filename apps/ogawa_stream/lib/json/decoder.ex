defmodule OgawaStream.Json.Decoder do
  def decode(data) when is_binary(data) do
    data = String.trim(data)

    case Poison.decode(data) do
      {:ok, data} when is_map(data) -> data
      {:ok, data} -> %{"error" => "Invalid data", "orig" => data}
      {:error, reason} -> %{"error" => "#{inspect(reason)}", "orig" => data}
    end
  end
end
