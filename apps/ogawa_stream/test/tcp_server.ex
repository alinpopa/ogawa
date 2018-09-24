defmodule OgawaStream.TcpServer do
  use GenServer

  def start(lines \\ []) do
    GenServer.start(__MODULE__, lines, [])
  end

  def init(lines) do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: true, reuseaddr: true])
    {:ok, port} = :inet.port(socket)
    Process.send_after(self(), :accept, 0)
    {:ok, %{port: port, socket: socket, lines: lines, client_socket: nil}}
  end

  def handle_call(:get_port, _from, state) do
    {:reply, state.port, state}
  end

  def handle_info(:accept, state) do
    {:ok, client_socket} = :gen_tcp.accept(state.socket)

    state.lines
    |> Enum.each(fn line ->
      :gen_tcp.send(client_socket, "#{line}\n")
    end)

    :gen_tcp.close(client_socket)
    {:noreply, state}
  end

  def handle_info(_info, state) do
    # Ignore various info messages (these can come from the socket itself)
    {:noreply, state}
  end

  def terminate(_reason, state) do
    if state.socket, do: :gen_tcp.close(state.socket)
    if state.client_socket, do: :gen_tcp.close(state.client_socket)
  end
end
