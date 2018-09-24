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
