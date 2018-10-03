defmodule Nerves.UsbAutomount.Config do
  @moduledoc false

  use GenServer

  require Logger

  @scope [:config, :usb_automount]
  # scope for detecting devices
  @device_scope [:state, "subsystems", "scsi_disk"]
  @priority :nerves_usb_automount

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init([]) do
    SystemRegistry.register(hysteresis: 50, min_interval: 1000)

    {:ok, %{}}
  end

  @doc false
  def handle_info({:system_registry, :global, registry}, s) do
    config = get_in(registry, @scope) || %{}
    s = update(config, s)
    {:noreply, s}
  end

  @doc false
  def update(old, old), do: old

  def update(new, old) do
    devices = get_in(new, @device_scope)
    Logger.debug("#{__MODULE__}: Updating new config for devices: #{inspect(devices)}")
    new
  end

end
