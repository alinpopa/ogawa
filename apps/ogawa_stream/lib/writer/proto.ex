defprotocol OgawaStream.Writer.Proto do
  def create(writer)

  def write(writer, data)

  def close(writer)
end
