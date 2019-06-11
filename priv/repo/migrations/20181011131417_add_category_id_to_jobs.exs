defmodule GroupherServer.Repo.Migrations.AddCategoryIdToJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs_favorites) do
      add(:category_id, references(:favorite_categories, on_delete: :delete_all))
    end

    create(index(:jobs_favorites, [:category_id]))
  end
end
