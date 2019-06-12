defmodule GroupherServer.Repo.Migrations.CreateCommunityThread do
  use Ecto.Migration

  def change do
    create table(:community_threads) do
      add(:title, :string)

      timestamps()
    end
  end
end
