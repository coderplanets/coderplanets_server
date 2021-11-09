defmodule GroupherServer.Repo.Migrations.WorksJoinTeammates do
  use Ecto.Migration

  def change do
    create table(:works_join_teammates) do
      add(:works_id, references(:cms_works, on_delete: :delete_all), null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
    end

    create(unique_index(:works_join_teammates, [:works_id, :user_id]))
  end
end
