defmodule OgawaStream.StreamReader do
  use GenServer
  alias OgawaStream, as: Ogawa
  alias Ogawa.Proto.Reader, as: Reader

  defmodule State do
    defstruct device: nil,
              sender: nil,
              freq: nil
  end

  def start(device, sender, freq \\ 0) do
    state = %State{
      device: device,
      sender: sender,
      freq: freq
    }

    GenServer.start(__MODULE__, state, [])
  end

  def async(device, freq, f) do
    Task.async(fn ->
      f.(create_stream(device, freq))
    end)
  end

  defp create_stream(device, freq) do
    Stream.resource(
      fn ->
        {:ok, pid} = start(device, self(), freq * 1000)
        pid
      end,
      fn pid ->
        GenServer.cast(pid, :get_line)

        receive do
          {:ok, data} -> {[data], pid}
          :done -> {:halt, pid}
          {:error, _reason} -> {:halt, pid}
        end
      end,
      &GenServer.stop/1
    )
  end

  def init(state), do: {:ok, state}

  def handle_cast(:get_line, state) do
    Process.send_after(self(), :get_line, state.freq)
    {:noreply, state}
  end

  def handle_info(:get_line, state) do
    {msg, state} =
      case Reader.read_line(state.device) do
        {:done, device} ->
          {:done, %State{state | device: device}}

        {:error, reason} ->
          {{:error, {:invalid_data, reason}}, state}

        {data, device} ->
          {{:ok, data}, %State{state | device: device}}
      end

    Process.send(state.sender, msg, [])
    {:noreply, state}
  end

  def terminate(_reason, state),
    do: Reader.close(state.device)
end
