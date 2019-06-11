defmodule GroupherServer.Repo.Migrations.ReplaceUserSexWithDefaultValue do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:sex)
      add(:sex, :string, default: "dude")
    end
  end
end
