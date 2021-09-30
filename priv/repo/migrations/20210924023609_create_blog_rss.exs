defmodule GroupherServer.Repo.Migrations.CreateBlogRss do
  use Ecto.Migration

  def change do
    create table(:cms_blog_rss) do
      add(:rss, :string)
      add(:link, :string)
      add(:title, :string)
      add(:subtitle, :string)
      add(:updated, :string)
      add(:history_feed, :map)
      add(:author, :map)
    end

    create(unique_index(:cms_blog_rss, [:rss, :link]))
  end
end
