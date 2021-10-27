defmodule GroupherServer.Repo.Migrations.AddRawToTechstack do
  use Ecto.Migration

  def change do
    alter table(:cms_techstacks) do
      add(:raw, :string)
    end
  end
end
