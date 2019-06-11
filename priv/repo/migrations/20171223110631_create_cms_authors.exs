defmodule GroupherServer.Repo.Migrations.CreateCmsAuthors do
  use Ecto.Migration

  def change do
    create table(:cms_authors) do
      add(:role, :string)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:cms_authors, [:user_id]))
  end
end
