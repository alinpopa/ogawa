defprotocol OgawaStream.Reader.Proto do
  def create(reader)

  def read_line(reader)

  def close(reader)
end
