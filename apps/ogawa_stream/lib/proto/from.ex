defprotocol OgawaStream.Proto.From do
  @fallback_to_any true
  def from(reader)
end

defimpl OgawaStream.Proto.From, for: Any do
  def from(_reader), do: nil
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.File do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.From, for: List do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Socket do
  def from(reader), do: reader
end

defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Stdin do
  def from(reader), do: reader
end
