defprotocol OgawaStream.Proto.To do
  @fallback_to_any true
  def to(writer)
end
