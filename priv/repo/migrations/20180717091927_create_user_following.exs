defmodule GroupherServer.Repo.Migrations.CreateUserFollowing do
  use Ecto.Migration

  def change do
    create table(:users_followings) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:following_id, references(:users, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:users_followings, [:user_id, :following_id]))
  end
end
