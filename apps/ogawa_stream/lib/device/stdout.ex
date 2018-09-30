defmodule OgawaStream.Device.Stdout do
  defstruct device: :stdio
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Stdout do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.Writer, for: OgawaStream.Device.Stdout do
  def create(writer), do: {:ok, writer}

  def write(writer, stream) do
    Stream.each(stream, fn elem ->
      IO.puts(writer.device, elem)
    end)
    |> Stream.run()
  end

  def close(_writer), do: :ok
end
