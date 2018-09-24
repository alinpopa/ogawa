defmodule OgawaStream.Writer.FileTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Writer.Proto, as: ProtoWriter

  @test_file "some_file_used_for_testing.txt"

  defp remove_test_file do
    File.rm(Path.join(:code.priv_dir(:ogawa_stream), @test_file))
  end

  describe "OgawaStream.Writer.Proto.Writer.create/1" do
    test "should successfully create a file stream on disk" do
      on_exit(fn -> remove_test_file() end)
      file = Path.join(:code.priv_dir(:ogawa_stream), @test_file)
      {:ok, writer} = ProtoWriter.create(Ogawa.Device.File.create(file))

      assert writer.file == file
    end
  end

  describe "OgawaStream.Writer.Proto.Writer.write/2" do
    test "should successfully write empty stream to file" do
      on_exit(fn -> remove_test_file() end)
      file = Path.join(:code.priv_dir(:ogawa_stream), @test_file)

      {:ok, writer} = ProtoWriter.create(Ogawa.Device.File.create(file))

      :ok = ProtoWriter.write(writer, [])

      content =
        File.stream!(file)
        |> Enum.to_list()

      assert content == []
    end

    test "should successfully write non-empty stream to file" do
      on_exit(fn -> remove_test_file() end)
      file = Path.join(:code.priv_dir(:ogawa_stream), @test_file)

      {:ok, writer} = ProtoWriter.create(Ogawa.Device.File.create(file))

      :ok = ProtoWriter.write(writer, ["test1", "test2"])

      content =
        File.stream!(file)
        |> Enum.to_list()

      assert content == ["test1\n", "test2\n"]
    end
  end
end
