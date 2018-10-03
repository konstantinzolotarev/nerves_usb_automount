defmodule Nerves.UsbAutomount.Device do
  @moduledoc false

  use GenServer
  alias Nerves.UsbAutomount.Types.Device

  require Logger

  @mount_dir Application.get_env(:nerves_usb_automount, :mount_dir, "/tmp")
  @mount_options Application.get_env(:nerves_usb_automount, :mount_options, "defaults")

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
  {:ok, %Nerves.UsbAutomount.Types.Device{device: "/dev/sdb1", label: "UNTITLED", type: "vfat", uuid: "08FB-E2C7"}}
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

  @doc """
  Check if device already mounted
  """
  @spec mounted?(Nerves.UsbAutomount.Types.Device.t()) :: boolean
  def mounted?(%Device{device: dev, uuid: uuid}) do
    path = Path.absname("#{@mount_dir}/#{uuid}")

    with {:ok, content} <- File.read("/proc/mounts"),
         result <- content =~ "#{dev} #{path}" do
      result
    else
      err ->
        Logger.error("Failed to read /proc/mounts with error #{inspect(err)}")
        false
    end
  end

  @doc """
  Mount device.
  """
  @spec mount(Nerves.UsbAutomount.Types.Device.t()) :: {:ok, binary} | {:error, term}
  def mount(%Device{device: dev, uuid: uuid}) do
    path = Path.absname("#{@mount_dir}/#{uuid}")
    Logger.debug("Mounting #{dev} into #{path}")

    with false <- File.dir?(path),
         :ok <- File.mkdir(path),
         {"", 0} <- System.cmd("mount", ["-o", @mount_options, dev, path]) do
      Logger.debug("Mounted #{dev} to #{path}")
      {:ok, path}
    else
      true ->
        Logger.error("Dir #{path} already exist for mount #{dev}")
        {:error, :dir_already_exist}

      {:error, err} ->
        Logger.error("Failed to create dir #{path} for mount #{dev}")
        {:error, err}

      {"", code} ->
        Logger.error("Fialed to mount #{dev} to #{path} with code #{inspect(code)}")
        {:error, :failed_to_mount}

      _ ->
        {:error, :something_wrong}
    end
  end

  @doc """
  Unmount device or mounted path.
  """
  @spec umount(binary | Nerves.UsbAutomount.Types.Device.t()) :: :ok | {:error, term}
  def umount(path) when is_binary(path) do
    with true <- File.dir?(path),
         {"", 0} <- System.cmd("umount", [path]),
         {:ok, _} <- File.rm_rf(path) do
      :ok
    else
      false ->
        Logger.debug("No dir #{path} exist. Nothing to unmount")
        :ok

      {"", code} ->
        Logger.error("Failed to umount #{path} with exit code: #{inspect(code)}")
        {:error, :error_unmounting}

      {:error, err} ->
        Logger.error("Failed to remove #{path} with err #{inspect(err)}")
        {:error, err}

      _ ->
        {:error, :unknown_error}
    end
  end

  def umount(%Device{uuid: uuid}) do
    "#{@mount_dir}/#{uuid}"
    |> Path.absname()
    |> umount()
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
