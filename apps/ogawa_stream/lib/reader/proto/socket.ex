defimpl OgawaStream.Reader.Proto, for: OgawaStream.Device.Socket do
  alias OgawaStream, as: Ogawa

  def create(reader) do
    case Ogawa.Tcp.Socket.start(reader.host, reader.port) do
      {:ok, pid} ->
        {:ok, %Ogawa.Device.Socket{reader | pid: pid}}

      {:error, reason} ->
        {:error, {:socket_connection, {reader.host, reader.port}, reason}}
    end
  end

  def read_line(reader) do
    case Ogawa.Tcp.Socket.get_line(reader.pid) do
      {:ok, data} -> {data, reader}
      {:error, :closed} -> {:done, reader}
      {:error, reason} -> {:error, reason}
    end
  end

  def close(reader) do
    Ogawa.Tcp.Socket.close(reader.pid)
  end
end
