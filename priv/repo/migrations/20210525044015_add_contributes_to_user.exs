defmodule GroupherServer.Repo.Migrations.AddContributesToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:contributes, :map)
    end
  end
end
