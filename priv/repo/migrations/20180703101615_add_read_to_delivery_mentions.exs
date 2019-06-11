defmodule GroupherServer.Repo.Migrations.AddReadToDeliveryMentions do
  use Ecto.Migration

  def change do
    alter table(:mentions) do
      add(:read, :boolean, default: false)
    end
  end
end
