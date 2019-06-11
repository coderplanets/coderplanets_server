defmodule GroupherServer.Repo.Migrations.CreateCommunityEditors do
  use Ecto.Migration

  def change do
    create table(:communities_editors) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:title, :string)

      timestamps()
    end

    create(unique_index(:communities_editors, [:user_id, :community_id]))
    create(index(:communities_editors, [:community_id]))
    create(index(:communities_editors, [:user_id]))
    create(index(:communities_editors, [:title]))
  end
end
