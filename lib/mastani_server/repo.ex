defmodule MastaniServer.Repo do
  import Helper.Utils, only: [get_config: 2]

  use Ecto.Repo, otp_app: :mastani_server
  use Scrivener, page_size: get_config(:pagi, :page_size)

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
