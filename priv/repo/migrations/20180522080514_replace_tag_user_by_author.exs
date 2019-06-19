defmodule GroupherServer.Repo.Migrations.ReplaceTagUserByAuthor do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      remove(:user_id)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
    end
  end
end
