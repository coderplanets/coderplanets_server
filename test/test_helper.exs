ExUnit.configure(exclude: :later, trace: false, formatters: [ExUnit.CLIFormatter, ExUnitNotifier])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(GroupherServer.Repo, :manual)
