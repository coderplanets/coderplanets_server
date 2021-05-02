defmodule GroupherServer.Repo.Migrations.AddMetaToCollectFolder do
  use Ecto.Migration

  def change do
    alter table(:collect_folders) do
      add(:meta, :map)
    end
  end
end
