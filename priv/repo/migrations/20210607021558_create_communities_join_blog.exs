defmodule GroupherServer.Repo.Migrations.CreateCommunitiesJoinBlog do
  use Ecto.Migration

  def change do
    create table(:communities_join_blogs) do
      add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all), null: false)
    end

    create(unique_index(:communities_join_blogs, [:community_id, :blog_id]))
  end
end
