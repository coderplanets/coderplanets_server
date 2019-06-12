defmodule GroupherServer.Repo.Migrations.AddDefaultIndexToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:index, :integer, default: 100_000)
    end
  end
end
