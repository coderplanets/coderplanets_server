defmodule GroupherServer.Repo.Migrations.AddRepliesCountToArtcileComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:replies_count, :integer, default: 0)
    end
  end
end
