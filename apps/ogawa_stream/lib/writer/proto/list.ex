defimpl OgawaStream.Writer.Proto, for: List do
  def create(writer) do
    {:ok, writer}
  end

  def write(writer, stream) do
    stream |> Enum.into(writer)
  end

  def close(_writer) do
    :ok
  end
end
