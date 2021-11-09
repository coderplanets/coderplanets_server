defmodule GroupherServer.Repo.Migrations.AddShortbioToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:shortbio, :string)
    end
  end
end
