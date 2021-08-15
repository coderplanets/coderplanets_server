defmodule GroupherServer.Repo.Migrations.AddArchiveFieldsToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:is_archived, :boolean, default: false)
      add(:archived_at, :utc_datetime)
    end
  end
end
