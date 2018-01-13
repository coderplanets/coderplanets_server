defmodule MastaniServer.Repo.Migrations.RemoveExtraInfoInPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      remove(:isRefined)
      remove(:isSticky)
      remove(:viewerCanStar)
      remove(:viewerCanWatch)
      remove(:viewerCanCollect)
    end
  end
end
