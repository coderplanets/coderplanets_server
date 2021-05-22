defmodule GroupherServer.Repo.Migrations.AddMetaToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:meta, :map)
    end
  end
end
