defmodule GroupherServer.Repo.Migrations.AddFloorToVideoComment do
  use Ecto.Migration

  def change do
    alter table(:videos_comments) do
      add(:floor, :integer, default: 0)
    end

    create(index(:videos_comments, [:floor]))
    create(unique_index(:videos_comments, [:video_id, :author_id, :floor]))
  end
end
