defimpl OgawaStream.Writer.Proto, for: OgawaStream.Device.File do
  def create(writer) do
    {:ok, %OgawaStream.Device.File{writer | device: File.stream!(writer.file, [:write, :utf8])}}
  end

  def write(writer, stream) do
    stream
    |> Stream.map(fn line -> [line, "\n"] end)
    |> Stream.into(writer.device)
    |> Stream.run()
  end

  def close(writer) do
    File.close(writer.device)
  end
end
