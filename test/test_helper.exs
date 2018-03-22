ExUnit.configure(exclude: :later, trace: true, formatters: [ExUnit.CLIFormatter, ExUnitNotifier])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(MastaniServer.Repo, :manual)
