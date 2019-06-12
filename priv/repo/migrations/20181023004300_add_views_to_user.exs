defmodule GroupherServer.Repo.Migrations.AddViewsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:views, :integer, default: 0)
    end
  end
end
