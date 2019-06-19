defmodule GroupherServer.Repo.Migrations.AddPayInfosToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:sponsor_member, :boolean, default: false)
      add(:paid_member, :boolean, default: false)
      add(:platinum_member, :boolean, default: false)
    end
  end
end
