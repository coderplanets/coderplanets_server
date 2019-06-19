defmodule GroupherServer.Repo.Migrations.RenameTagPartToThread do
  use Ecto.Migration

  def change do
    rename(table(:tags), :part, to: :thread)

    # drop(unique_index(:tags, [:community, :part, :title]))
    # create(unique_index(:tags, [:community, :thread, :title]))
  end
end
