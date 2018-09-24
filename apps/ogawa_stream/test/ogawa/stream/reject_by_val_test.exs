defmodule OgawaStream.RejectByValTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  describe "OgawaStream.reject_by_val/2" do
    test "should reject objects based on value" do
      reader = [%{a: "val1", b: "val2"}, %{a: "val3", b: "val4"}, %{a: "val5", b: "val6"}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.reject_by_val("val3")
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a.a < b.a end)
      assert result == [%{a: "val1", b: "val2"}, %{a: "val5", b: "val6"}]
    end

    test "should reject multiple objects" do
      reader = [%{a: "val1", b: "val2"}, %{a: "val3", b: "val4"}, %{a: "val5", b: "val6"}]

      result =
        Ogawa.make()
        |> Ogawa.from(reader)
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.reject_by_val("val3")
        |> Ogawa.reject_by_val("val1")
        |> Ogawa.to([])
        |> Ogawa.sync()

      result = result |> Enum.sort(fn a, b -> a.a < b.a end)
      assert result == [%{a: "val5", b: "val6"}]
    end
  end
end
