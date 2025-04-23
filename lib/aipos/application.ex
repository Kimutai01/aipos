defmodule Aipos.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AiposWeb.Telemetry,
      Aipos.Repo,
      {Cachex, name: :ussd_session_cache},
      {DNSCluster, query: Application.get_env(:aipos, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Aipos.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Aipos.Finch},
      # Start a worker by calling: Aipos.Worker.start_link(arg)
      # {Aipos.Worker, arg},
      # Start to serve requests, typically the last entry
      AiposWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Aipos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AiposWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
