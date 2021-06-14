defmodule GroupherServer.Repo.Migrations.MissongPopcornEmotion do
  use Ecto.Migration

  def change do
    alter table(:comments_users_emotions) do
      add(:popcorn, :boolean, default: false)
    end
  end
end
