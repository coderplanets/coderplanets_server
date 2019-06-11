defmodule GroupherServer.Repo.Migrations.AddLoginToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:login, :string)
    end
  end
end
