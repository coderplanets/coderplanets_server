defmodule GroupherServer.Repo.Migrations.AlterC11nTheme do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      remove(:theme)
      add(:theme, :string)
    end
  end
end
