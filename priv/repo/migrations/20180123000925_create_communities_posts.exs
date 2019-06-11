defmodule GroupherServer.Repo.Migrations.CreateCommunitiesPosts do
  use Ecto.Migration

  def change do
    create table(:communities_posts) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_posts, [:community_id, :post_id]))
  end
end
