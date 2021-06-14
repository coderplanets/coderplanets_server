defmodule GroupherServer.Repo.Migrations.RemoveArticlePrefixInArtilces do
  use Ecto.Migration

  def change do
    rename(table(:cms_posts), :article_comments_participants, to: :comments_participants)
    rename(table(:cms_posts), :article_comments_count, to: :comments_count)

    rename(table(:cms_posts), :article_comments_participants_count,
      to: :comments_participants_count
    )

    rename(table(:cms_jobs), :article_comments_participants, to: :comments_participants)
    rename(table(:cms_jobs), :article_comments_count, to: :comments_count)

    rename(table(:cms_jobs), :article_comments_participants_count,
      to: :comments_participants_count
    )

    rename(table(:cms_repos), :article_comments_participants, to: :comments_participants)
    rename(table(:cms_repos), :article_comments_count, to: :comments_count)

    rename(table(:cms_repos), :article_comments_participants_count,
      to: :comments_participants_count
    )

    rename(table(:cms_blogs), :article_comments_participants, to: :comments_participants)
    rename(table(:cms_blogs), :article_comments_count, to: :comments_count)

    rename(table(:cms_blogs), :article_comments_participants_count,
      to: :comments_participants_count
    )
  end
end
