defmodule GroupherServer.Application do
  @moduledoc false
  use Application
  import Helper.Utils, only: [get_config: 2]

  alias Helper.Cache

  @cache_pool get_config(:cache, :pool)

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the PubSub system
        {Phoenix.PubSub, name: MyApp.PubSub},
        # Start the Ecto repository
        supervisor(GroupherServer.Repo, []),
        # Start the endpoint when the application starts
        supervisor(GroupherServerWeb.Endpoint, []),
        # Start your own worker by calling: GroupherServer.Worker.start_link(arg1, arg2, arg3)
        worker(Helper.Scheduler, []),
        {Rihanna.Supervisor, [postgrex: GroupherServer.Repo.config()]}
      ] ++ cache_workers()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GroupherServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GroupherServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp cache_workers() do
    import Supervisor.Spec

    # worker(GroupherServer.Worker, [arg1, arg2, arg3]),
    # worker(Cachex, [:common, Cache.config(:common)], id: :common),
    # worker(Cachex, [:user_login, Cache.config(:user_login)], id: :user_login),
    # worker(Cachex, [:blog_rss, Cache.config(:blog_rss)], id: :blog_rss),

    @cache_pool
    |> Map.keys()
    |> Enum.reduce([], fn key, acc ->
      name = @cache_pool[key].name
      acc ++ [worker(Cachex, [name, Cache.config(key)], id: name)]
    end)
  end
end
