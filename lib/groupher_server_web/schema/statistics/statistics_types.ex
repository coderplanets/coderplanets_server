defmodule GroupherServerWeb.Schema.Statistics.Types do
  use Absinthe.Schema.Notation

  # import GroupherServerWeb.Schema.Helper.Fields

  # alias GroupherServer.Accounts

  object :user_contribute do
    meta(:cache, max_age: 30)
    field(:count, :integer)
    field(:date, :date)
  end

  object :online_status_info do
    field(:realtime_visitors, :integer)
  end

  object :count_status_info do
    field(:communities_count, :integer)
    field(:posts_count, :integer)
    field(:jobs_count, :integer)
    field(:works_count, :integer)
    field(:meetups_count, :integer)
    field(:radars_count, :integer)
    field(:blogs_count, :integer)
    field(:guides_count, :integer)
    field(:drinks_count, :integer)

    field(:categories_count, :integer)
    field(:article_tags_count, :integer)
    field(:threads_count, :integer)
  end
end
