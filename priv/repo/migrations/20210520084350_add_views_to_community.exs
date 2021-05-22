defmodule GroupherServer.Repo.Migrations.AddViewsToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:views, :integer, default: 0)
    end
  end
end
