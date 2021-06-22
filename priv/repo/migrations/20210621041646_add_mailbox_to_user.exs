defmodule GroupherServer.Repo.Migrations.AddMailboxToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:mailbox, :map)
    end
  end
end
