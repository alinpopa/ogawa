defimpl OgawaStream.Proto.To, for: OgawaStream.Device.Stdout do
  def to(writer), do: writer
end
