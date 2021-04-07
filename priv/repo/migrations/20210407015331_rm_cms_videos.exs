defmodule GroupherServer.Repo.Migrations.RmCmsVideos do
  use Ecto.Migration

  def change do
    drop(table(:pined_videos))
    drop(table(:videos_viewers))
    drop(table(:videos_favorites))
    drop(table(:videos_stars))
    drop(table(:communities_videos))
    drop(table(:videos_tags))

    drop(table(:videos_communities_flags))
    drop(table(:videos_comments_replies))
    drop(table(:videos_comments_likes))
    drop(table(:videos_comments_dislikes))

    drop(table(:videos_comments))

    drop(table(:cms_videos))
  end
end
