defmodule GroupherServer.Repo.Migrations.MoveFollowCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:followings_count, :integer)
      add(:followers_count, :integer)
    end
  end
end
