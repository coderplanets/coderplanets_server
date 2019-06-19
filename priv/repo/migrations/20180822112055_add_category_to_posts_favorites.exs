defmodule GroupherServer.Repo.Migrations.AddCategoryToPostsFavorites do
  use Ecto.Migration

  def change do
    alter table(:posts_favorites) do
      add(:category_title, :string, default: "all")
    end
  end
end
