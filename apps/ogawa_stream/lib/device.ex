defimpl OgawaStream.Proto.From, for: Any do
  def from(_reader), do: nil
end

defimpl OgawaStream.Proto.To, for: Any do
  def to(_writer), do: nil
end

defimpl OgawaStream.Proto.From, for: List do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.To, for: List do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.Reader, for: List do
  def create(list), do: {:ok, list}

  def read_line([h | t]), do: {h, t}

  def read_line([]), do: {:done, []}

  def close(_list), do: :ok
end

defimpl OgawaStream.Proto.Writer, for: List do
  def create(writer), do: {:ok, writer}

  def write(writer, stream), do: stream |> Enum.into(writer)

  def close(_writer), do: :ok
end
