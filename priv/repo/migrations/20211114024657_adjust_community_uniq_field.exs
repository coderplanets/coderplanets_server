defmodule GroupherServer.Repo.Migrations.AdjustCommunityUniqField do
  use Ecto.Migration

  def change do
    drop(unique_index(:communities, [:title]))
    create(unique_index(:communities, [:raw]))
  end
end
