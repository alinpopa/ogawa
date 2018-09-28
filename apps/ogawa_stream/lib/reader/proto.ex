defprotocol OgawaStream.Reader.Proto do
  def create(reader)

  def read_line(reader)

  def close(reader)
end

defimpl OgawaStream.Reader.Proto, for: OgawaStream.Device.File do
  alias OgawaStream, as: Ogawa

  def create(reader) do
    case File.open(reader.file) do
      {:ok, device} ->
        {:ok, %Ogawa.Device.File{reader | device: device}}

      {:error, reason} ->
        {:error, {:opening_file, reader.file, reason}}
    end
  end

  def read_line(reader) do
    case IO.read(reader.device, :line) do
      :eof -> {:done, reader}
      {:error, reason} -> {:error, reason}
      data -> {data, reader}
    end
  end

  def close(reader) do
    File.close(reader.device)
  end
end

defimpl OgawaStream.Reader.Proto, for: List do
  def create(list), do: {:ok, list}

  def read_line([h | t]), do: {h, t}

  def read_line([]), do: {:done, []}

  def close(_list), do: :ok
end

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

defimpl OgawaStream.Reader.Proto, for: OgawaStream.Device.Stdin do
  def create(reader), do: {:ok, reader}

  def read_line(reader) do
    case IO.gets(reader.device, "") do
      :eof -> {:done, reader}
      {:error, reason} -> {:error, reason}
      data -> {data, reader}
    end
  end

  def close(_reader), do: :ok
end
