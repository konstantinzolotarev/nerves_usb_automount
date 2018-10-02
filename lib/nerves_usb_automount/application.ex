defmodule NervesUsbAutomount.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: NervesUsbAutomount.Worker.start_link(arg)
      # {NervesUsbAutomount.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NervesUsbAutomount.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
