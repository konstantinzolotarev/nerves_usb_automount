defmodule Nerves.UsbAutomount.MixProject do
  use Mix.Project

  @version "0.1.0"

  @description """
  Simple USB automount package for Nerves
  """

  def project do
    [
      app: :nerves_usb_automount,
      version: @version,
      description: @description,
      package: package(),
      elixir: "~> 1.6",
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Nerves.UsbAutomount.Application, []}
    ]
  end

  defp package() do
    %{
      maintainers: ["Konstantin Zolotarev"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/konstantinzolotarev/nerves_usb_automount"}
    }
  end

  defp docs() do
    [main: "readme", extras: ["README.md"]]
  end

  defp deps do
    [
      {:system_registry, "~> 0.7"},
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5.1", only: [:dev, :test], runtime: false}
    ]
  end
end
