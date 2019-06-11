defmodule GroupherServer.Repo.Migrations.AddPriveteToFavoritesCategory do
  use Ecto.Migration

  def change do
    alter table(:favorite_categories) do
      add(:private, :boolean, default: false)
    end
  end
end
