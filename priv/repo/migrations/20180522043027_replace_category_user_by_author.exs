defmodule GroupherServer.Repo.Migrations.ReplaceCategoryUserByAuthor do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      remove(:user_id)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
    end
  end
end
