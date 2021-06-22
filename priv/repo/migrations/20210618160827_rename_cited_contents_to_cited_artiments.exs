defmodule GroupherServer.Repo.Migrations.RenameCitedContentsToCitedArtiments do
  use Ecto.Migration

  def change do
    drop(index(:cited_contents, [:cited_by_type, :cited_by_id]))
    rename(table(:cited_contents), to: table(:cited_artiments))
    create(index(:cited_artiments, [:cited_by_type, :cited_by_id]))
  end
end
