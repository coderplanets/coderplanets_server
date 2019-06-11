defmodule GroupherServer.Repo.Migrations.RemoveCategoryTitleInPostFavrotes do
  use Ecto.Migration

  def change do
    alter table(:posts_favorites) do
      remove(:category_title)
    end
  end
end
