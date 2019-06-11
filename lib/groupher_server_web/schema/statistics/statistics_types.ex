defmodule GroupherServerWeb.Schema.Statistics.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: GroupherServer.Repo

  # import GroupherServerWeb.Schema.Utils.Helper

  # alias GroupherServer.Accounts

  object :user_contribute do
    meta(:cache, max_age: 30)
    field(:count, :integer)
    field(:date, :date)
  end

  object :count_status_info do
    field(:communities_count, :integer)
    field(:posts_count, :integer)
    field(:jobs_count, :integer)
    field(:videos_count, :integer)
    field(:repos_count, :integer)

    field(:categories_count, :integer)
    field(:tags_count, :integer)
    field(:threads_count, :integer)
  end
end
