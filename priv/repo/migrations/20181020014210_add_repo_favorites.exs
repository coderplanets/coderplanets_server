defmodule GroupherServer.Repo.Migrations.AddRepoFavorites do
  use Ecto.Migration

  def change do
    create table(:repos_favorites) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:repo_id, references(:cms_repos, on_delete: :delete_all), null: false)
      add(:category_id, references(:favorite_categories, on_delete: :delete_all))

      timestamps()
    end

    create(index(:repos_favorites, [:category_id]))
    create(unique_index(:repos_favorites, [:user_id, :repo_id]))
  end
end
