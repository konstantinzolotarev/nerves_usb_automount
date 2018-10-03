defmodule Nerves.UsbAutomount.Types do
  defmodule Device do
    @moduledoc """
    Device details
    """

    @type t :: %__MODULE__{
            device: binary | nil,
            label: binary,
            uuid: binary,
            type: binary
          }

    defstruct device: nil, label: "UNKNOWN", uuid: nil, type: nil
  end
end
