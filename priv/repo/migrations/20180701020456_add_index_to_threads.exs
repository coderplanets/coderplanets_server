defmodule GroupherServer.Repo.Migrations.AddIndexToThreads do
  use Ecto.Migration

  def change do
    alter table(:threads) do
      add(:index, :integer, default: 0)
    end
  end
end
