defmodule GroupherServer.Repo.Migrations.RemoveQqInUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:qq)
    end
  end
end
