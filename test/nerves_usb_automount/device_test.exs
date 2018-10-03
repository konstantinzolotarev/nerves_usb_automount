defmodule Nerves.UsbAutomount.DeviceTest do
  use ExUnit.Case

  alias Nerves.UsbAutomount.Device

  describe "blkid_parse() :: " do
    test "parsing success" do
      {:ok, %Nerves.UsbAutomount.Types.Device{} = device} =
        "/dev/sdb1: LABEL=\"UNTITLED\" UUID=\"08FB-E2C7\" TYPE=\"vfat\""
        |> Device.blkid_parse()

      assert "/dev/sdb1" == device.device
      assert "UNTITLED" == device.label
      assert "08FB-E2C7" == device.uuid
      assert "vfat" == device.type
    end
  end
end
