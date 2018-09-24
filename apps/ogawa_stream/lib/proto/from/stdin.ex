defimpl OgawaStream.Proto.From, for: OgawaStream.Device.Stdin do
  def from(reader), do: reader
end
