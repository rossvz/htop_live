defmodule Htop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HtopWeb.Telemetry,
      Htop.Repo,
      {Phoenix.PubSub, name: Htop.PubSub},
      {Finch, name: Htop.Finch},
      HtopWeb.Endpoint,
      Htop.Metrics
    ]

    opts = [strategy: :one_for_one, name: Htop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    HtopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
