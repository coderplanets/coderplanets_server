defmodule GroupherServer.Repo.Migrations.AlterCustomizationTheme do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      remove(:theme)
      add(:theme, :string)
    end
  end
end
