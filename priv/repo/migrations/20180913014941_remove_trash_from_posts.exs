defmodule GroupherServer.Repo.Migrations.RemoveTrashFromPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      remove(:trash)
    end
  end
end
