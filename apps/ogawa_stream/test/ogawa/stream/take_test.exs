defmodule OgawaStream.TakeTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  describe "OgawaStream.take/2" do
    test "should retrieve only a limited number of records from the stream" do
      reader = [%{"name" => "x"}, %{"name" => "y"}, %{"name" => "z"}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.take(2)
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a["name"] < b["name"] end)
      assert result == [%{"name" => "x"}, %{"name" => "y"}]
    end

    test "should take only one element out of the limited retrieve results" do
      reader = [%{"name" => "x"}, %{"name" => "y"}, %{"name" => "z"}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.take(2)
        |> Ogawa.take(1)
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a["name"] < b["name"] end)
      assert result == [%{"name" => "x"}]
    end
  end
end
