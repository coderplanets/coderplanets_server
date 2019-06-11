defmodule GroupherServer.Repo.Migrations.AddFloorToComments do
  use Ecto.Migration

  def change do
    alter table(:posts_comments) do
      add(:floor, :integer, default: 0)
    end

    create(index(:posts_comments, [:floor]))
    create(unique_index(:posts_comments, [:post_id, :author_id, :floor]))
  end
end
