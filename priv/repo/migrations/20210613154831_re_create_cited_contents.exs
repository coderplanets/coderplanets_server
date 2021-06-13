defmodule GroupherServer.Repo.Migrations.ReCreateCitedContents do
  use Ecto.Migration

  def change do
    create table(:cited_contents) do
      # cited_type, cited_content_id, [contents]_id, [block_id, cited_block_id],
      add(:cited_by_type, :string)
      add(:cited_by_id, :id)

      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:comment_id, references(:comments, on_delete: :delete_all))

      add(:post_id, references(:cms_posts, on_delete: :delete_all))
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
      add(:job_id, references(:cms_jobs, on_delete: :delete_all))
      add(:blog_id, references(:cms_blogs, on_delete: :delete_all))

      add(:block_linker, {:array, :string})
    end

    create(index(:cited_contents, [:cited_by_type, :cited_by_id]))
  end
end
