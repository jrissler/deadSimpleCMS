defmodule DeadSimpleCms.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DeadSimpleCmsWeb.Telemetry,
      DeadSimpleCms.Repo,
      {DNSCluster, query: Application.get_env(:dead_simple_cms, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DeadSimpleCms.PubSub},
      # Start a worker by calling: DeadSimpleCms.Worker.start_link(arg)
      # {DeadSimpleCms.Worker, arg},
      # Start to serve requests, typically the last entry
      DeadSimpleCmsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DeadSimpleCms.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DeadSimpleCmsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
