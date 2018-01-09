defmodule MastaniServer.Repo.Migrations.CreatePostStars do
  use Ecto.Migration

  def change do
    create table(:post_stars) do
      add(:user_id, references(:users), primary_key: true)
      add(:post_id, references(:cms_posts), primary_key: true)

      timestamps()
    end

    create(unique_index(:post_stars, [:user_id, :post_id]))
  end
end
