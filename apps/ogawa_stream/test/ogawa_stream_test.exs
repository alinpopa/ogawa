defmodule OgawaStreamTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  test "create empty stream" do
    assert Ogawa.make() == %Ogawa{}
  end

  test "accept list as a reader" do
    ogawa = Ogawa.from(Ogawa.make(), [])

    assert ogawa.reader == []
  end

  test "accept list as a writer" do
    ogawa = Ogawa.to(Ogawa.make(), [])

    assert ogawa.writer == []
  end

  test "default value for max results of a created stream, should be 100 elements" do
    ogawa = Ogawa.from(Ogawa.make(), [])

    assert ogawa.max_results == 100
  end

  test "should be able to customize the stream max results" do
    ogawa = Ogawa.from(Ogawa.make(), [], 23)

    assert ogawa.max_results == 23
  end

  test "should accept custom decoder" do
    ogawa = Ogawa.make() |> Ogawa.decode_with(:custom_decoder)

    assert ogawa.decoder == :custom_decoder
  end

  test "should accept custom encoder" do
    ogawa = Ogawa.make() |> Ogawa.encode_with(:custom_encoder)

    assert ogawa.encoder == :custom_encoder
  end

  test "should be able to work with non string streams" do
    result =
      Ogawa.make()
      |> Ogawa.from([%{a: :b}, %{a: :c}])
      |> Ogawa.decode_with(& &1)
      |> Ogawa.encode_with(& &1)
      |> Ogawa.to([])
      |> Ogawa.sync()

    result = result |> Enum.sort(fn x, y -> x.a < y.a end)
    assert result == [%{a: :b}, %{a: :c}]
  end

  test "should be tolerant to invalid json records" do
    result =
      Ogawa.make()
      |> Ogawa.from(["wrong json value"])
      |> Ogawa.to([])
      |> Ogawa.sync()

    assert Enum.count(result) == 1
    [value] = result
    assert is_binary(value)
  end

  test "should be able to use custom decoders" do
    decoder = fn data ->
      String.split(data, ",")
      |> Enum.map(fn value -> String.split(value, ":") end)
      |> Map.new(fn values -> List.to_tuple(values) end)
    end

    result =
      Ogawa.make()
      |> Ogawa.from(["x:100,y:200", "x:300,y:400"])
      |> Ogawa.decode_with(decoder)
      |> Ogawa.encode_with(fn data -> data end)
      |> Ogawa.to([])
      |> Ogawa.sync()

    result = result |> Enum.sort(fn a, b -> a["x"] < b["x"] end)
    assert result == [%{"x" => "100", "y" => "200"}, %{"x" => "300", "y" => "400"}]
  end

  test "should be able to use custom encoders" do
    decoder = fn data ->
      String.split(data, ",")
      |> Enum.map(fn value -> String.split(value, ":") end)
      |> Map.new(fn values -> List.to_tuple(values) end)
    end

    encoder = fn data ->
      Map.keys(data)
      |> Enum.sort(fn a, b -> a < b end)
    end

    result =
      Ogawa.make()
      |> Ogawa.from(["x:100,y:200", "x:300,y:400"])
      |> Ogawa.decode_with(decoder)
      |> Ogawa.encode_with(encoder)
      |> Ogawa.to([])
      |> Ogawa.sync()

    assert result == [["x", "y"], ["x", "y"]]
  end

  test "should filter out data that doesn't meet specific condition" do
    result =
      Ogawa.make()
      |> Ogawa.from([2, 0, 5, 0, 8, 0])
      |> Ogawa.decode_with(& &1)
      |> Ogawa.encode_with(& &1)
      |> Ogawa.filter(fn x -> x != 0 end)
      |> Ogawa.to([])
      |> Ogawa.sync()

    assert result == [2, 5, 8]
  end

  test "should map given values to different values" do
    result =
      Ogawa.make()
      |> Ogawa.from([1, 2, 3])
      |> Ogawa.decode_with(& &1)
      |> Ogawa.encode_with(& &1)
      |> Ogawa.map(fn x -> x * x end)
      |> Ogawa.to([])
      |> Ogawa.sync()

    assert result == [1, 4, 9]
  end
end
