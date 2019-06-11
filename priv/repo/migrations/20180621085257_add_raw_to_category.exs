defmodule GroupherServer.Repo.Migrations.AddRawToCategory do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add(:raw, :string)
    end

    create(unique_index(:categories, [:raw]))
  end
end
