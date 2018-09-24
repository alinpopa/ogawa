defmodule OgawaStream.Device.File do
  defstruct file: nil,
            device: nil

  def create(file) do
    %OgawaStream.Device.File{
      file: file,
      device: nil
    }
  end
end
