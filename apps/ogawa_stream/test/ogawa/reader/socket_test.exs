defmodule OgawaStream.Reader.SocketTest do
  use ExUnit.Case
  doctest OgawaStream
  alias OgawaStream, as: Ogawa
  alias Ogawa.Reader.Proto, as: ProtoReader

  defp start_server(lines \\ []) do
    {:ok, pid} = Ogawa.TcpServer.start(lines)
    port = GenServer.call(pid, :get_port, :infinity)
    %{pid: pid, port: port}
  end

  defp stop_server(server) do
    GenServer.stop(server.pid)
  end

  describe "OgawaStream.Reader.Proto.Reader.create/1" do
    test "should successfully create a connection to an existing server" do
      server = start_server()
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(Ogawa.Device.Socket.create('127.0.0.1', server.port))
      assert not is_nil(device.host)
      assert is_pid(device.pid)
      assert is_integer(device.port)
    end

    test "should fail gracefully when not able to connect to a tcp server" do
      server = start_server()
      stop_server(server)

      reader = ProtoReader.create(Ogawa.Device.Socket.create('127.0.0.1', server.port))
      assert {:error, {:socket_connection, {'127.0.0.1', port}, _}} = reader
    end
  end

  describe "OgawaStream.Reader.Proto.Reader.read_line/1" do
    test "should successfully read all lines from server" do
      server = start_server(["line1"])
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(Ogawa.Device.Socket.create('127.0.0.1', server.port))
      result = ProtoReader.read_line(device)
      assert {"line1\n", device} == result
    end

    test "should return nothing when the server closes the socket" do
      server = start_server([])
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(Ogawa.Device.Socket.create('127.0.0.1', server.port))
      result = ProtoReader.read_line(device)
      assert {:done, device} == result
    end

    test "should read all lines when doing consecutive readings" do
      server = start_server(["line1", "line2", "line3"])
      on_exit(fn -> stop_server(server) end)

      {:ok, device} = ProtoReader.create(Ogawa.Device.Socket.create('127.0.0.1', server.port))
      result = ProtoReader.read_line(device)
      assert {"line1\n", device} == result
      result = ProtoReader.read_line(device)
      assert {"line2\n", device} == result
      result = ProtoReader.read_line(device)
      assert {"line3\n", device} == result
      result = ProtoReader.read_line(device)
      assert {:done, device} == result
      result = ProtoReader.read_line(device)
      assert {:error, _} = result
    end
  end
end
