defmodule GroupherServer.Repo do
  import Helper.Utils, only: [get_config: 2]

  use Ecto.Repo, otp_app: :groupher_server, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: get_config(:general, :page_size)

  @dialyzer {:nowarn_function, rollback: 1}

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
