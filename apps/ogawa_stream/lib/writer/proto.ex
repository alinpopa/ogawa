defprotocol OgawaStream.Writer.Proto do
  def create(writer)

  def write(writer, data)

  def close(writer)
end

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

defimpl OgawaStream.Writer.Proto, for: List do
  def create(writer), do: {:ok, writer}

  def write(writer, stream), do: stream |> Enum.into(writer)

  def close(_writer), do: :ok
end

defimpl OgawaStream.Writer.Proto, for: OgawaStream.Device.Socket do
  alias OgawaStream, as: Ogawa

  def create(writer) do
    case Ogawa.Tcp.Socket.start(writer.host, writer.port) do
      {:ok, pid} ->
        {:ok, %Ogawa.Device.Socket{writer | pid: pid}}

      {:error, reason} ->
        {:error, {:socket_connection, {writer.host, writer.port}, reason}}
    end
  end

  def write(writer, stream) do
    Stream.each(stream, fn elem ->
      Ogawa.Tcp.Socket.write_line(writer.pid, elem)
    end)
    |> Stream.run()
  end

  def close(writer) do
    Ogawa.Tcp.Socket.close(writer.pid)
  end
end

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
