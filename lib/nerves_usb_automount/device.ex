defmodule Nerves.UsbAutomount.Device do
  @moduledoc false

  use GenServer
  alias Nerves.UsbAutomount.Types.Device

  require Logger

  defmodule State do
    @moduledoc false

    @enforce_keys [:device]
    defstruct device: nil,
              mounted: false,
              mount_point: nil
  end

  @doc false
  def start_link(device) when is_binary(device) do
    GenServer.start_link(__MODULE__, %State{device: %Device{device: device}})
  end

  def init(%State{device: device} = state), do: {:ok, state}

  #
  # Public functions
  #

  @doc """
  Parses device definition from `blkid`
  
  [blkid details](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/s2-sysinfo-filesystems-blkid)

  Usage:
  ```elixir
  iex(2)> "/dev/sdb1: LABEL=\"UNTITLED\" UUID=\"08FB-E2C7\" TYPE=\"vfat\"" |> Nerves.UsbAutomount.Device.blkid_parse()
  {:ok, %{device: "/dev/sdb1", label: "UNTITLED", type: "vfat", uuid: "08FB-E2C7"}}
  ```
  """
  @spec blkid_parse(binary) :: {:ok, Nerves.UsbAutomount.Types.Device.t()} | {:error, term}
  def blkid_parse(string) do
    case Regex.run(~r/^[^:]*/, string) do
      [device] when is_binary(device) ->
        {:ok,
         %Nerves.UsbAutomount.Types.Device{
           device: device,
           label: blkid_pick("LABEL", string),
           uuid: blkid_pick("UUID", string),
           type: blkid_pick("TYPE", string)
         }}

      _ ->
        {:error, :wrong_device}
    end
  end

  # Pick required part value from blkid string
  defp blkid_pick(part, string) do
    case Regex.run(~r/.*#{part}=\"([^"]*)\"/, string) do
      [_, res] ->
        res

      _ ->
        nil
    end
  end
end
