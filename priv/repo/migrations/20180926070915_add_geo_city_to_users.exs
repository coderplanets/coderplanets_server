defmodule GroupherServer.Repo.Migrations.AddGeoCityToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:geo_city, :string)
    end

    create(index(:users, [:geo_city]))
  end
end
