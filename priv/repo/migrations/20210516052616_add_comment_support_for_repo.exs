defmodule GroupherServer.Repo.Migrations.AddCommentSupportForRepo do
  use Ecto.Migration

  def change do
    alter table(:cms_repos) do
      add(:article_comments_participators_count, :integer, default: 0)
      add(:article_comments_count, :integer, default: 0)
      add(:article_comments_participators, :map)
    end
  end
end
