defmodule GroupherServer.Repo.Migrations.AddWorksToCitedArtiments do
  use Ecto.Migration

  def change do
    alter table(:cited_artiments) do
      add(:works_id, references(:cms_works, on_delete: :delete_all))
    end
  end
end
