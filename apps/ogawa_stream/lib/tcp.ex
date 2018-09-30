defmodule OgawaStream.Tcp do
  defmodule Socket do
    use GenServer

    defmodule State do
      defstruct host: nil,
                port: nil,
                socket: nil
    end

    def start(host, port) do
      state = %State{
        host: host,
        port: port
      }

      GenServer.start(__MODULE__, state, [])
    end

    def get_line(pid),
      do: GenServer.call(pid, :get_line, :infinity)

    def write_line(pid, line),
      do: GenServer.cast(pid, {:write_line, line})

    def close(pid),
      do: GenServer.stop(pid)

    def init(state) do
      opts = [:binary, active: false, packet: :line]

      case :gen_tcp.connect(state.host, state.port, opts) do
        {:ok, socket} -> {:ok, %State{socket: socket}}
        {:error, reason} -> {:stop, reason}
      end
    end

    def handle_call(:get_line, _from, state) do
      case :gen_tcp.recv(state.socket, 0) do
        {:ok, data} -> {:reply, {:ok, data}, state}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end

    def handle_cast({:write_line, line}, state) do
      case :gen_tcp.send(state.socket, "#{line}\n") do
        :ok -> {:noreply, state}
        {:error, _reason} -> {:noreply, state}
      end
    end

    def terminate(_reason, state),
      do: :gen_tcp.close(state.socket)
  end
end
