defmodule GroupherServer.Repo.Migrations.AddSubscribeCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:subscribed_communities_count, :integer)
    end
  end
end
