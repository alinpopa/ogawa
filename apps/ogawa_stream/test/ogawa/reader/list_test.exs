defmodule OgawaStream.Reader.ListTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Reader.Proto, as: ProtoReader

  describe "OgawaStream.Reader.Proto.Reader.create/1" do
    test "should return an empty list when the reader is an empty list" do
      reader = ProtoReader.create([])
      assert reader == {:ok, []}
    end

    test "should successfully return a created list" do
      reader = ProtoReader.create([1, 2, 3])
      assert reader == {:ok, [1, 2, 3]}
    end
  end

  describe "OgawaStream.Reader.Proto.Reader.read_line/1" do
    test "should return end of list when reading line from empty list" do
      assert ProtoReader.read_line([]) == {:done, []}
    end

    test "should return the first element, and the rest, of a non empty list" do
      assert ProtoReader.read_line([1, 2, 3]) == {1, [2, 3]}
    end

    test "should return the only element, and an empty list as rest, from a unary list" do
      assert ProtoReader.read_line([1]) == {1, []}
    end
  end
end
