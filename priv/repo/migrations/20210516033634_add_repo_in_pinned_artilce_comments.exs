defmodule GroupherServer.Repo.Migrations.AddRepoInPinnedArtilceComments do
  use Ecto.Migration

  def change do
    alter table(:articles_pined_comments) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end

    create(index(:articles_pined_comments, [:repo_id]))

    create(
      unique_index(:articles_pined_comments, [:post_id, :job_id, :repo_id, :article_comment_id])
    )
  end
end
