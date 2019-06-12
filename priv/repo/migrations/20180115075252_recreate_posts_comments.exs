defmodule GroupherServer.Repo.Migrations.RecreatePostsComments do
  use Ecto.Migration

  def change do
    create table(:posts_comments) do
      add(:body, :string)
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:posts_comments, [:author_id]))
    create(index(:posts_comments, [:post_id]))
  end
end
