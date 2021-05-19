defmodule GroupherServer.Repo.Migrations.CreateArticleTags do
  use Ecto.Migration

  def change do
    create table(:article_tags) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:thread, :string)
      add(:title, :string)
      add(:color, :string)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)

      timestamps()
    end

    # create(unique_index(:tags, [:community, :part, :title]))
  end
end
