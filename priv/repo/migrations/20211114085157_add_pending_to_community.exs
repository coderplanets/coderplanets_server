defmodule GroupherServer.Repo.Migrations.AddPendingToCommunity do
  use Ecto.Migration

  def change do
    alter(table(:communities), do: add(:pending, :integer, default: 0))
  end
end
