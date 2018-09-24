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
