defmodule GroupherServer.Repo.Migrations.AddEmbedsRepliesToArtcileComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:replies, :map)
    end
  end
end
