defmodule OgawaStream.ToTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa

  describe "OgawaStream.to/2" do
    test "should not start the stream when passing an unsupported writer" do
      result =
        Ogawa.make()
        |> Ogawa.from([1, 2, 3])
        |> Ogawa.decode_with(& &1)
        |> Ogawa.encode_with(& &1)
        |> Ogawa.to(%{})
        |> Ogawa.sync()

      assert result == {:error, :invalid_writer}
    end
  end
end
