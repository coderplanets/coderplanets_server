defmodule GroupherServer.Repo.Migrations.AddHoverToC11n do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      add(:content_hover, :boolean)
    end
  end
end
