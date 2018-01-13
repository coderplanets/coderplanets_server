defmodule MastaniServer.Repo.Migrations.DropPostsCommentsUniqueIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:posts_comments, [:writer_id, :post_id]))
  end
end
