defmodule GroupherServer.Repo.Migrations.AddNoteBillRecords do
  use Ecto.Migration

  def change do
    alter table(:bill_records) do
      add(:note, :text)
    end
  end
end
