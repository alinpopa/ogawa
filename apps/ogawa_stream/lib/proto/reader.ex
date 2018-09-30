defprotocol OgawaStream.Proto.Reader do
  def create(reader)

  def read_line(reader)

  def close(reader)
end
