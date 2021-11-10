defmodule GroupherServer.Repo.Migrations.AddPendingToArticles do
  use Ecto.Migration

  def change do
    alter(table(:cms_posts), do: add(:pending, :integer, default: 0))
    alter(table(:cms_jobs), do: add(:pending, :integer, default: 0))
    alter(table(:cms_blogs), do: add(:pending, :integer, default: 0))
    alter(table(:cms_works), do: add(:pending, :integer, default: 0))
    alter(table(:cms_radars), do: add(:pending, :integer, default: 0))
    alter(table(:cms_drinks), do: add(:pending, :integer, default: 0))
    alter(table(:cms_meetups), do: add(:pending, :integer, default: 0))
    alter(table(:cms_guides), do: add(:pending, :integer, default: 0))
  end
end
