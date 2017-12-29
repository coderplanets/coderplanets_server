defmodule MastaniServer.Repo.Migrations.CreateCmsPostsUsers do
  use Ecto.Migration

  def change do
    create table(:users_posts) do
      add(:user_id, references(:users))
      add(:post_id, references(:cms_posts))
    end

    create(unique_index(:users_posts, [:user_id, :post_id]))
  end
end
