defmodule OgawaStream.Device.Stdin do
  defstruct device: :stdio
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Stdin do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.Reader, for: OgawaStream.Device.Stdin do
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
