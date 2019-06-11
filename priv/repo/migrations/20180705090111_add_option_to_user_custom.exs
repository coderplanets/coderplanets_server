defmodule GroupherServer.Repo.Migrations.AddOptionToUserCustom do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      add(:sidebar_layout, :map)
    end
  end
end
