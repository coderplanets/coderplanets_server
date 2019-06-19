defmodule GroupherServer.Repo.Migrations.AddMemberToAchievements do
  use Ecto.Migration

  def change do
    alter table(:user_achievements) do
      add(:donate_member, :boolean, default: false)
      add(:senior_member, :boolean, default: false)
      add(:sponsor_member, :boolean, default: false)
    end

    create(index(:user_achievements, [:donate_member]))
    create(index(:user_achievements, [:senior_member]))
    create(index(:user_achievements, [:sponsor_member]))
  end
end
