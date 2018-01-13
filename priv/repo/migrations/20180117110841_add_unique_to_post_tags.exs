defmodule MastaniServer.Repo.Migrations.AddUniqueToPostTags do
  use Ecto.Migration

  def change do
    create(unique_index(:post_tags, [:title]))
  end
end
