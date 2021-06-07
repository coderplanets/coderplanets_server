defmodule GroupherServer.Repo.Migrations.CreateBlogs do
  use Ecto.Migration

  def change do
    create table(:cms_blogs) do
      add(:title, :string)
      add(:views, :integer, default: 0)
      add(:mark_delete, :boolean, default: false)
      add(:meta, :map)
      add(:emotions, :map)
      add(:original_community_id, references(:communities, on_delete: :delete_all))
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)

      add(:active_at, :utc_datetime)

      # reaction
      add(:upvotes_count, :integer, default: 0)
      add(:collects_count, :integer, default: 0)

      # comments
      add(:article_comments_participators_count, :integer, default: 0)
      add(:article_comments_count, :integer, default: 0)
      add(:article_comments_participators, :map)

      # domain
      add(:digest, :string)
      add(:link_addr, :string)
      add(:length, :integer)
    end

    create(index(:cms_blogs, [:author_id]))
  end
end
