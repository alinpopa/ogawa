defmodule OgawaStream do
  defstruct reader: nil,
            writer: nil,
            max_results: 0,
            decoder: nil,
            encoder: nil,
            started: false,
            freq: 0,
            reducers: [],
            filters: [],
            mappers: []

  alias OgawaStream, as: Ogawa
  alias Ogawa.Proto.From, as: ProtoFrom
  alias Ogawa.Proto.To, as: ProtoTo
  alias Ogawa.Reader.Proto, as: ProtoReader
  alias Ogawa.Writer.Proto, as: ProtoWriter

  def make(), do: %Ogawa{}

  def from(ogawa, reader, max_results \\ 100) do
    reader = ProtoFrom.from(reader)
    %Ogawa{ogawa | reader: reader, max_results: max_results}
  end

  def to(ogawa, writer) do
    writer = ProtoTo.to(writer)
    %Ogawa{ogawa | writer: writer}
  end

  def decode_with(ogawa, decoder),
    do: %Ogawa{ogawa | decoder: decoder}

  def encode_with(ogawa, encoder),
    do: %Ogawa{ogawa | encoder: encoder}

  def map(ogawa, f),
    do: %Ogawa{ogawa | mappers: [f | ogawa.mappers]}

  def take(ogawa, n),
    do: %Ogawa{ogawa | reducers: [n | ogawa.reducers]}

  def throttle(ogawa, n),
    do: %Ogawa{ogawa | freq: n}

  def reject_by_val(ogawa, val) do
    rejection = fn data ->
      not Enum.any?(Map.values(data), fn v -> v == val end)
    end

    %Ogawa{ogawa | filters: [rejection | ogawa.filters]}
  end

  def filter_by_val(ogawa, val) do
    filter = fn data ->
      Enum.any?(Map.values(data), fn v -> v == val end)
    end

    %Ogawa{ogawa | filters: [filter | ogawa.filters]}
  end

  def filter(ogawa, filter), do: %Ogawa{ogawa | filters: [filter | ogawa.filters]}

  def add_pair(ogawa, key, val) do
    %Ogawa{ogawa | mappers: [fn data -> Map.put(data, key, val) end | ogawa.mappers]}
  end

  def remove_key(ogawa, key) do
    %Ogawa{ogawa | mappers: [fn data -> Map.delete(data, key) end | ogawa.mappers]}
  end

  def prefix_key(ogawa, key, prefix) do
    mapper = fn data ->
      data
      |> Enum.map(fn
        {k, v} when k == key -> {"#{prefix}#{k}", v}
        entry -> entry
      end)
      |> Enum.into(%{})
    end

    %Ogawa{ogawa | mappers: [mapper | ogawa.mappers]}
  end

  def async(ogawa = %Ogawa{started: false}) do
    ogawa = %Ogawa{ogawa | started: true}

    with {:ok, ogawa} <- vet(ogawa),
         {:ok, reader} <- ProtoReader.create(ogawa.reader),
         {:ok, writer} <- ProtoWriter.create(ogawa.writer) do
      Ogawa.Reader.Process.async(reader, ogawa.freq, fn stream ->
        stream
        |> apply_decoder(ogawa)
        |> apply_mappers(ogawa)
        |> apply_reducers(ogawa)
        |> apply_filters(ogawa)
        |> apply_encoder(ogawa)
        |> write(writer)
      end)
    else
      {:error, reason} ->
        Task.async(fn -> {:error, reason} end)
    end
  end

  def async(_ogawa),
    do: Task.async(fn -> {:error, :invalid_stream} end)

  def sync(ogawa = %Ogawa{}), do: async(ogawa) |> sync()

  def sync(task = %Task{}), do: Task.await(task, :infinity)

  defp apply_decoder(stream, ogawa) do
    ogawa =
      case ogawa.decoder do
        nil -> %Ogawa{ogawa | decoder: &Ogawa.Json.Decoder.decode/1}
        decoder -> %Ogawa{ogawa | decoder: decoder}
      end

    Stream.map(stream, ogawa.decoder)
  end

  defp apply_encoder(stream, ogawa) do
    ogawa =
      case ogawa.encoder do
        nil -> %Ogawa{ogawa | encoder: &Ogawa.Json.Encoder.encode/1}
        encoder -> %Ogawa{ogawa | encoder: encoder}
      end

    Stream.map(stream, ogawa.encoder)
  end

  defp write(stream, writer) do
    ProtoWriter.write(writer, stream)
  end

  defp vet(%Ogawa{reader: nil}),
    do: {:error, :invalid_reader}

  defp vet(%Ogawa{writer: nil}),
    do: {:error, :invalid_writer}

  defp vet(%Ogawa{freq: freq})
       when is_nil(freq) or not is_integer(freq) or freq < 0,
       do: {:error, {:invalid_throttling, freq}}

  defp vet(%Ogawa{max_results: max})
       when is_nil(max) or (not is_integer(max) and max != :all) or max < 0,
       do: {:error, {:invalid_max_results, max}}

  defp vet(ogawa = %Ogawa{reducers: reducers}) do
    invalid_values =
      Enum.any?(reducers, fn
        reducer when not is_integer(reducer) -> true
        reducer when is_nil(reducer) -> true
        reducer when reducer < 0 -> true
        _ -> false
      end)

    case invalid_values do
      true -> {:error, :invalid_reducers}
      false -> {:ok, ogawa}
    end
  end

  defp vet(input),
    do: {:error, {:invalid_stream, input}}

  defp apply_mappers(stream, ogawa) do
    Enum.reverse(ogawa.mappers)
    |> Enum.reduce(stream, fn mapper, acc ->
      acc |> Stream.map(mapper)
    end)
  end

  defp apply_reducers(stream, %Ogawa{max_results: :all}),
    do: stream

  defp apply_reducers(stream, ogawa) do
    reducers = Enum.reverse(ogawa.reducers)

    case reducers do
      [] -> stream |> Stream.take(ogawa.max_results)
      _ -> reducers |> Enum.reduce(stream, fn n, acc -> acc |> Stream.take(n) end)
    end
  end

  defp apply_filters(stream, ogawa) do
    Enum.reverse(ogawa.filters)
    |> Enum.reduce(stream, fn filter, acc ->
      acc |> Stream.filter(filter)
    end)
  end
end
