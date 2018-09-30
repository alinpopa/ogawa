defmodule OgawaStream.Reader.FileTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Proto.Reader

  @test_file "some_file_used_for_testing.txt"

  defp create_test_file do
    File.write(Path.join(:code.priv_dir(:ogawa_stream), @test_file), "This is a test")
  end

  defp remove_test_file do
    File.rm(Path.join(:code.priv_dir(:ogawa_stream), @test_file))
  end

  setup do
    create_test_file()
    :ok
  end

  describe "Reader.create/1" do
    test "should fail gracefully when file doesn't exist" do
      on_exit(fn -> remove_test_file() end)

      file = Path.join(:code.priv_dir(:ogawa_stream), "no_file.here")
      reader = Reader.create(Ogawa.Device.File.create(file))
      assert reader == {:error, {:opening_file, file, :enoent}}
    end

    test "should successfully create file reader when passing a valid file" do
      on_exit(fn -> remove_test_file() end)

      file = Path.join(:code.priv_dir(:ogawa_stream), @test_file)
      reader = Reader.create(Ogawa.Device.File.create(file))
      {:ok, %Ogawa.Device.File{device: pid}} = reader
      assert is_pid(pid)
    end
  end

  describe "Reader.read_line/1" do
    test "should not return anything when reading an empty file" do
      file_name = "test_one_line.txt"

      on_exit(fn ->
        remove_test_file()
        File.rm(Path.join(:code.priv_dir(:ogawa_stream), file_name))
      end)

      File.write(Path.join(:code.priv_dir(:ogawa_stream), file_name), "")

      file = Path.join(:code.priv_dir(:ogawa_stream), file_name)
      {:ok, device} = Reader.create(Ogawa.Device.File.create(file))

      line = Reader.read_line(device)
      assert line == {:done, device}
    end

    test "should return the line and then signaling the end of file" do
      on_exit(fn -> remove_test_file() end)

      file = Path.join(:code.priv_dir(:ogawa_stream), @test_file)
      {:ok, device} = Reader.create(Ogawa.Device.File.create(file))

      assert Reader.read_line(device) == {"This is a test", device}
      assert Reader.read_line(device) == {:done, device}
    end
  end
end
