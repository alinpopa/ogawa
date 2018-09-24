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
