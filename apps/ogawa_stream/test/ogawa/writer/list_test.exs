defmodule OgawaStream.Writer.ListTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Writer.Proto, as: ProtoWriter

  describe "OgawaStream.Writer.Proto.Writer.create/1" do
    test "should return an empty list when the writer is an empty list" do
      writer = ProtoWriter.create([])
      assert writer == {:ok, []}
    end

    test "should successfully return a created list" do
      writer = ProtoWriter.create([1, 2, 3])
      assert writer == {:ok, [1, 2, 3]}
    end
  end

  describe "OgawaStream.Writer.Proto.Writer.write/2" do
    test "should return a non empty list when writing into an empty list" do
      assert ProtoWriter.write([], 1..3) == [1, 2, 3]
    end

    test "should append to elements existing from a given list" do
      assert ProtoWriter.write([1, 2, 3], 4..6) == [1, 2, 3, 4, 5, 6]
    end
  end
end
