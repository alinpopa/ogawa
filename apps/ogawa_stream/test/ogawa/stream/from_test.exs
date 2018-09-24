defmodule OgawaStream.FromTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  describe "OgawaStream.from/1" do
    test "should fetch only a maximum of 100 elements if no other value specified" do
      reader = Enum.to_list(1..101)

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a < b end)
      assert result == Enum.to_list(1..100)
    end

    test "should fetch only a maximum of given elements" do
      reader = Enum.to_list(1..100)

      result =
        Ogawa.make()
        |> Ogawa.from(reader, 17)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a < b end)
      assert result == Enum.to_list(1..17)
    end

    test "should fetch all available elements from the reader" do
      reader = Enum.to_list(1..105)

      result =
        Ogawa.make()
        |> Ogawa.from(reader, :all)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a < b end)
      assert result == Enum.to_list(1..105)
    end

    test "should fail starting the stream when given invalid elements limit number" do
      reader = Enum.to_list(1..108)

      result =
        Ogawa.make()
        |> Ogawa.from(reader, -6)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == {:error, {:invalid_max_results, -6}}
    end

    test "should fail starting the stream when given other atom than ':all'" do
      reader = Enum.to_list(1..108)

      result =
        Ogawa.make()
        |> Ogawa.from(reader, :none)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == {:error, {:invalid_max_results, :none}}
    end

    test "should not start the stream when passing an unsupported reader" do
      result =
        Ogawa.make()
        |> Ogawa.from(%{key1: :value, key2: :value})
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == {:error, :invalid_reader}
    end
  end
end
