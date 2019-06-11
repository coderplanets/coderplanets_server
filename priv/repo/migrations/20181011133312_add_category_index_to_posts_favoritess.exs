defmodule GroupherServer.Repo.Migrations.AddCategoryIndexToPostsFavoritess do
  use Ecto.Migration

  def change do
    create(index(:posts_favorites, [:category_id]))
  end
end
