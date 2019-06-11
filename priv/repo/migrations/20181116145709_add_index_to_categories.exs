defmodule GroupherServer.Repo.Migrations.AddIndexToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add(:index, :integer, default: 0)
    end
  end
end
