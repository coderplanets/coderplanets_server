defmodule GroupherServer.Application do
  @moduledoc false
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    import Cachex.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(GroupherServer.Repo, []),
      # Start the endpoint when the application starts
      supervisor(GroupherServerWeb.Endpoint, []),
      # Start your own worker by calling: GroupherServer.Worker.start_link(arg1, arg2, arg3)
      # worker(GroupherServer.Worker, [arg1, arg2, arg3]),
      worker(Cachex, [
        :site_cache,
        [
          limit:
            limit(
              # the limit provided
              size: 5000,
              # the policy to use for eviction
              policy: Cachex.Policy.LRW,
              # how much to reclaim on bound expiration
              reclaim: 0.1,
              # options to pass to the policy
              options: []
            )
        ]
      ]),
      {Rihanna.Supervisor, [postgrex: GroupherServer.Repo.config()]}
    ]

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
end
