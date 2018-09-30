defprotocol OgawaStream.Proto.Writer do
  def create(writer)

  def write(writer, data)

  def close(writer)
end
