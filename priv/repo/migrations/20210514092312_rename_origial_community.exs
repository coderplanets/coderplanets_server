defmodule GroupherServer.Repo.Migrations.RenameOrigialCommunity do
  use Ecto.Migration

  def change do
    rename(table(:cms_posts), :origial_community_id, to: :original_community_id)
    rename(table(:cms_jobs), :origial_community_id, to: :original_community_id)
    rename(table(:cms_repos), :origial_community_id, to: :original_community_id)
  end
end
