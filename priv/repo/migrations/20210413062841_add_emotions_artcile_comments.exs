defmodule GroupherServer.Repo.Migrations.AddEmotionsArtcileComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      add(:emotions, :map)
    end
  end
end
