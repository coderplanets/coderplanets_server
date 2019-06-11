defmodule GroupherServer.Repo.Migrations.AddFloorToMentions do
  use Ecto.Migration

  def change do
    alter table(:mentions) do
      add(:floor, :integer)
    end
  end
end
