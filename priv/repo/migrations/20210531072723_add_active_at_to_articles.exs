defmodule GroupherServer.Repo.Migrations.AddActiveAtToArticles do
  use Ecto.Migration

  # see https://elixirforum.com/t/ecto-datetime-and-utc-naive-datetime-in-migration/21213

  def change do
    alter(table(:cms_posts), do: add(:active_at, :utc_datetime))
    alter(table(:cms_jobs), do: add(:active_at, :utc_datetime))
    alter(table(:cms_repos), do: add(:active_at, :utc_datetime))
  end
end
