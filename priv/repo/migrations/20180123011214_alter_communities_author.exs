defmodule GroupherServer.Repo.Migrations.AlterCommunitiesAuthor do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      remove(:author)
      add(:user_id, references(:users), null: false)
    end

    create(index(:communities, [:user_id]))
  end
end
