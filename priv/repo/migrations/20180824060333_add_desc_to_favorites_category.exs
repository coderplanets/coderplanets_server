defmodule GroupherServer.Repo.Migrations.AddDescToFavoritesCategory do
  use Ecto.Migration

  def change do
    alter table(:favorite_categories) do
      add(:desc, :string)
    end
  end
end
