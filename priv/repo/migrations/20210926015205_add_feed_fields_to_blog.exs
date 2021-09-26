defmodule GroupherServer.Repo.Migrations.AddFeedFieldsToBlog do
  use Ecto.Migration

  def change do
    alter table(:cms_blogs) do
      add(:feed_digest, :string)
      add(:feed_content, :text)
      add(:published, :string)
      add(:blog_author, :map)
    end
  end
end
