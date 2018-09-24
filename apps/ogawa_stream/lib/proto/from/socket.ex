defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Socket do
  def from(reader), do: reader
end
