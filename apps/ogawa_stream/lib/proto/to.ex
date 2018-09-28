defprotocol OgawaStream.Proto.To do
  @fallback_to_any true
  def to(writer)
end

defimpl OgawaStream.Proto.To, for: Any do
  def to(_writer), do: nil
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.File do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.To, for: List do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Socket do
  def to(writer), do: writer
end

defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Stdout do
  def to(writer), do: writer
end
