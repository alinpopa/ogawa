defmodule OgawaStream.Device.Socket do
  defstruct host: nil,
            port: nil,
            pid: nil

  def create(host, port) do
    %OgawaStream.Device.Socket{host: host, port: port}
  end
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Socket do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Socket do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.Reader, for: OgawaStream.Device.Socket do
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

defimpl OgawaStream.Proto.Writer, for: OgawaStream.Device.Socket do
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
