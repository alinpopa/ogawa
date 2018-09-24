defimpl OgawaStream.Proto.To, for: OgawaStream.Device.File do
  def to(writer), do: writer
end
