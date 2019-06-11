defmodule GroupherServer.Repo.Migrations.AddAkaToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:aka, :string)
    end

    create(unique_index(:communities, [:aka]))
  end
end
