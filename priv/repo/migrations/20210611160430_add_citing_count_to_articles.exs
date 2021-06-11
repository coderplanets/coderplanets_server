defmodule GroupherServer.Repo.Migrations.AddCitingCountToArticles do
  use Ecto.Migration

  def change do
    alter(table(:cms_posts), do: add(:citing_count, :integer))
    alter(table(:cms_jobs), do: add(:citing_count, :integer))
    alter(table(:cms_repos), do: add(:citing_count, :integer))
    alter(table(:cms_blogs), do: add(:citing_count, :integer))
  end
end
