defmodule OgawaStream.Device.File do
  defstruct file: nil,
            device: nil

  def create(file) do
    %OgawaStream.Device.File{
      file: file,
      device: nil
    }
  end
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.File do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.File do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.Reader, for: OgawaStream.Device.File do
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

defimpl OgawaStream.Proto.Writer, for: OgawaStream.Device.File do
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
