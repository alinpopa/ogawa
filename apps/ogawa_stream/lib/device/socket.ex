defmodule OgawaStream.Device.Socket do
  defstruct host: nil,
            port: nil,
            pid: nil

  def create(host, port) do
    %OgawaStream.Device.Socket{host: host, port: port}
  end
end
