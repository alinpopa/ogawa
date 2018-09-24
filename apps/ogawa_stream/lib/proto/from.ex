defprotocol OgawaStream.Proto.From do
  @fallback_to_any true
  def from(reader)
end
