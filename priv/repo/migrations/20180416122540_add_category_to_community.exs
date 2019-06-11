defmodule GroupherServer.Repo.Migrations.AddCategoryToCommunity do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      add(:category, :string)
    end
  end
end
