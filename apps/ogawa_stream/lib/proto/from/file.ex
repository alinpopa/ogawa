defimpl OgawaStream.Proto.From, for: OgawaStream.Device.File do
  def from(reader), do: reader
end
