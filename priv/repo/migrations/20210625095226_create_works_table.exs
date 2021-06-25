defmodule GroupherServer.Repo.Migrations.CreateWorksTable do
  use Ecto.Migration

  def change do
    create table(:cms_works) do
      add(:thread, :string)
      add(:title, :string)
      add(:digest, :string)
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
      add(:comments_participants_count, :integer, default: 0)
      add(:comments_count, :integer, default: 0)
      add(:comments_participants, :map)

      timestamps()
    end

    create(index(:cms_works, [:author_id]))
  end
end
