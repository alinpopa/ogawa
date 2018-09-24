defmodule OgawaStream.AddPairTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  describe "OgawaStream.add_pair/2" do
    test "should add pair to empty objects" do
      reader = [%{}, %{}, %{}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.add_pair(:x, :y)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == [%{x: :y}, %{x: :y}, %{x: :y}]
    end

    test "should replace existing pairs when using the same key" do
      reader = [%{x: :z}, %{x: :z}, %{x: :z}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.add_pair(:x, :y)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == [%{x: :y}, %{x: :y}, %{x: :y}]
    end

    test "should overwrite the previously added pair for consecutive operations of the same key" do
      reader = [%{}, %{}, %{}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.add_pair(:x, :y)
        |> Ogawa.add_pair(:x, :z)
        |> Ogawa.to([])
        |> Ogawa.sync()

      assert result == [%{x: :z}, %{x: :z}, %{x: :z}]
    end
  end
end
