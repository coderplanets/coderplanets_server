defmodule GroupherServer.Repo.Migrations.CreateFavoritesCategories do
  use Ecto.Migration

  def change do
    create table(:favorite_categories) do
      add(:user_id, references(:users, on_delete: :delete_all, null: false))
      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      # add(:job_id, references(:cms_posts, on_delete: :delete_all), null: false)

      add(:title, :string)
      add(:total_count, :integer, default: 0)
      add(:index, :integer)

      timestamps()
    end

    create(unique_index(:favorite_categories, [:user_id, :title]))
  end
end
