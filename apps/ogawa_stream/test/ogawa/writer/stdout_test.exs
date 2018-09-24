defmodule OgawaStream.Writer.StdoutTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Writer.Proto, as: ProtoWriter

  defmodule TestStdout do
    use GenServer

    def start() do
      GenServer.start(__MODULE__, [], [])
    end

    def init([]) do
      {:ok, %{lines: []}}
    end

    def handle_info({:io_request, pid, ref, {_, _, line}}, state) do
      lines = [line | state.lines]
      state = %{state | lines: Enum.reverse(lines)}
      send(pid, {:io_reply, ref, nil})
      {:noreply, state}
    end

    def handle_call(:get_lines, _from, state) do
      {:reply, state.lines, state}
    end
  end

  defp start_server() do
    {:ok, pid} = TestStdout.start()
    %{pid: pid}
  end

  defp stop_server(server) do
    GenServer.stop(server.pid)
  end

  describe "OgawaStream.Writer.Proto.Writer.create/1" do
    test "should successfully create a stdout writer" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} = ProtoWriter.create(%Ogawa.Device.Stdout{device: server.pid})
      assert writer.device == server.pid
    end
  end

  describe "OgawaStream.Writer.Proto.Writer.write/2" do
    test "should successfully write an empty stream" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} = ProtoWriter.create(%Ogawa.Device.Stdout{device: server.pid})
      :ok = ProtoWriter.write(writer, [])
      assert GenServer.call(server.pid, :get_lines) == []
    end

    test "should successfully write an non-empty stream" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} = ProtoWriter.create(%Ogawa.Device.Stdout{device: server.pid})
      :ok = ProtoWriter.write(writer, ["line1", "line2"])
      assert GenServer.call(server.pid, :get_lines) == ["line1\n", "line2\n"]
    end
  end
end
