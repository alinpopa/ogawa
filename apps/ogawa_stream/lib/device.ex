defmodule OgawaStream.Device do
  defmodule File do
    defstruct file: nil,
              device: nil

    def create(file) do
      %OgawaStream.Device.File{
        file: file,
        device: nil
      }
    end
  end

  defmodule Socket do
    defstruct host: nil,
              port: nil,
              pid: nil

    def create(host, port) do
      %OgawaStream.Device.Socket{host: host, port: port}
    end
  end

  defmodule Stdin do
    defstruct device: :stdio
  end

  defmodule Stdout do
    defstruct device: :stdio
  end
end
