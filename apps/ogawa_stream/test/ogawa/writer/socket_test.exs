defmodule OgawaStream.Writer.SocketTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Writer.Proto, as: ProtoWriter

  defp start_server() do
    {:ok, pid} = Ogawa.TcpServer.start()
    port = GenServer.call(pid, :get_port, :infinity)
    %{pid: pid, port: port}
  end

  defp stop_server(server) do
    GenServer.stop(server.pid)
  end

  describe "OgawaStream.Writer.Proto.Writer.create/1" do
    test "should successfully create a socket writer" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} =
        ProtoWriter.create(%Ogawa.Device.Socket{host: '127.0.0.1', port: server.port})

      assert not is_nil(writer.pid)
    end

    test "should fail gracefully when server not available" do
      server = start_server()
      stop_server(server)

      assert {:error, {:socket_connection, {'127.0.0.1', _}, _}} =
               ProtoWriter.create(%Ogawa.Device.Socket{host: '127.0.0.1', port: server.port})
    end
  end

  describe "OgawaStream.Writer.Proto.Writer.write/2" do
    test "should successfully write an empty stream" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} =
        ProtoWriter.create(%Ogawa.Device.Socket{host: '127.0.0.1', port: server.port})

      assert :ok = ProtoWriter.write(writer, [])
    end

    test "should successfully write non-empty stream" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, writer} =
        ProtoWriter.create(%Ogawa.Device.Socket{host: '127.0.0.1', port: server.port})

      assert :ok = ProtoWriter.write(writer, ["one", "two"])
    end
  end
end
