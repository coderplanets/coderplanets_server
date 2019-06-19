defmodule GroupherServer.Repo.Migrations.AddUsersInfo do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:nickname, :string)
      add(:bio, :string)
      add(:company, :string)
    end
  end
end
