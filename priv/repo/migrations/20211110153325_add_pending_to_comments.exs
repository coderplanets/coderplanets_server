defmodule GroupherServer.Repo.Migrations.AddPendingToComments do
  use Ecto.Migration

  def change do
    alter(table(:comments), do: add(:pending, :integer, default: 0))
  end
end
