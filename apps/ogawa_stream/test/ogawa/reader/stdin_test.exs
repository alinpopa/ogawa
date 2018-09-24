defmodule OgawaStream.Reader.StdinTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Reader.Proto, as: ProtoReader

  defmodule TestStdin do
    use GenServer

    def start(lines \\ []) do
      GenServer.start(__MODULE__, lines, [])
    end

    def init(lines) do
      {:ok, %{lines: lines}}
    end

    def handle_info({:io_request, pid, ref, {:get_line, _, _}}, state) do
      lines =
        case state.lines do
          [] ->
            send(pid, {:io_reply, ref, :eof})
            []

          [h | tail] ->
            send(pid, {:io_reply, ref, "#{h}\n"})
            tail
        end

      {:noreply, %{state | lines: lines}}
    end
  end

  defp start_server(lines \\ []) do
    {:ok, pid} = TestStdin.start(lines)
    %{pid: pid}
  end

  defp stop_server(server) do
    GenServer.stop(server.pid)
  end

  describe "OgawaStream.Reader.Proto.Reader.create/1" do
    test "should successfully create a stdin reader" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(%Ogawa.Device.Stdin{device: server.pid})
      assert %Ogawa.Device.Stdin{} = device
    end
  end

  describe "OgawaStream.Reader.Proto.Reader.read_line/1" do
    test "should return the end of the stream if getting eof from stdin" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(%Ogawa.Device.Stdin{device: server.pid})
      result = ProtoReader.read_line(device)
      assert result == {:done, device}
    end

    test "should read a single line from stdin and then eof" do
      server = start_server(["line1"])
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(%Ogawa.Device.Stdin{device: server.pid})
      result = ProtoReader.read_line(device)
      assert result == {"line1\n", device}
      result = ProtoReader.read_line(device)
      assert result == {:done, device}
    end

    test "should read all line from stdin then eof" do
      server = start_server(["line1", "line2", "line3"])
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(%Ogawa.Device.Stdin{device: server.pid})
      result = ProtoReader.read_line(device)
      assert result == {"line1\n", device}
      result = ProtoReader.read_line(device)
      assert result == {"line2\n", device}
      result = ProtoReader.read_line(device)
      assert result == {"line3\n", device}
      result = ProtoReader.read_line(device)
      assert result == {:done, device}
    end
  end
end
