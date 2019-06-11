defmodule GroupherServer.Repo.Migrations.TmpDropVideosCommentsFloorIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:videos_comments, [:video_id, :author_id, :floor]))
  end
end
