defmodule GroupherServer.Repo.Migrations.AddLastUpdatedToFavoriteCategories do
  use Ecto.Migration

  def change do
    alter table(:favorite_categories) do
      add(:last_updated, :utc_datetime)
    end
  end
end
