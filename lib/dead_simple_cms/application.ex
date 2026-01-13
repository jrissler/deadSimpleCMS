defmodule DeadSimpleCms.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    start_app? = Application.get_env(:dead_simple_cms, :start_app, false)

    children =
      if start_app? do
        [
          DeadSimpleCmsWeb.Telemetry,
          DeadSimpleCms.Repo,
          {DNSCluster, query: Application.get_env(:dead_simple_cms, :dns_cluster_query) || :ignore},
          {Phoenix.PubSub, name: DeadSimpleCms.PubSub},
          DeadSimpleCmsWeb.Endpoint
        ]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: DeadSimpleCms.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    if Application.get_env(:dead_simple_cms, :start_app, false) do
      DeadSimpleCmsWeb.Endpoint.config_change(changed, removed)
    end

    :ok
  end
end
