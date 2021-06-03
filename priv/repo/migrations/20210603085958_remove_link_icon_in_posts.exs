defmodule GroupherServer.Repo.Migrations.RemoveLinkIconInPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      remove(:link_icon)
    end
  end
end
