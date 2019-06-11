defmodule GroupherServer.Repo.Migrations.AddCmsAuthorIdToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
    end

    create(index(:cms_posts, [:author_id]))
  end
end
