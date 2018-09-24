defimpl OgawaStream.Writer.Proto, for: OgawaStream.Device.Stdout do
  def create(writer), do: {:ok, writer}

  def write(writer, stream) do
    Stream.each(stream, fn elem ->
      IO.puts(writer.device, elem)
    end)
    |> Stream.run()
  end

  def close(_writer), do: :ok
end
