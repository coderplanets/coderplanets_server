defmodule MastaniServer.Repo.Migrations.CreatePostFavorites do
  use Ecto.Migration

  def change do
    create table(:post_favorites) do
      add(:user_id, references(:users), primary_key: true)
      add(:post_id, references(:cms_posts), primary_key: true)

      timestamps()
    end

    create(unique_index(:post_favorites, [:user_id, :post_id]))
  end
end
