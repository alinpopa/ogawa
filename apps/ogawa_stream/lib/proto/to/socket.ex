defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Socket do
  def to(writer), do: writer
end
