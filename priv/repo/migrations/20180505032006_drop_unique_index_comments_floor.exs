defmodule GroupherServer.Repo.Migrations.DropUniqueIndexCommentsFloor do
  use Ecto.Migration

  def change do
    drop(unique_index(:posts_comments, [:post_id, :author_id, :floor]))
  end
end
