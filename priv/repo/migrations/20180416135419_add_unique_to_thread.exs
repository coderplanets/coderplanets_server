defmodule GroupherServer.Repo.Migrations.AddUniqueToThread do
  use Ecto.Migration

  def change do
    create(unique_index(:community_threads, [:title]))
  end
end
