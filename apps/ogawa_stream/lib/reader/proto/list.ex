defimpl OgawaStream.Reader.Proto, for: List do
  def create(list) do
    {:ok, list}
  end

  def read_line([h | t]),
    do: {h, t}

  def read_line([]),
    do: {:done, []}

  def close(_list) do
    :ok
  end
end
