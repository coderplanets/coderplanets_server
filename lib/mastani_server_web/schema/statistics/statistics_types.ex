defmodule MastaniServerWeb.Schema.Statistics.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  import MastaniServerWeb.Schema.Utils.Helper

  # alias MastaniServer.Accounts

  object :user_contribute do
    field(:count, :integer)
    field(:date, :date)
  end
end
