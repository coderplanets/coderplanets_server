defmodule MastaniServer.Repo.Migrations.AddMemberToAchievements do
  use Ecto.Migration

  def change do
    alter table(:user_achievements) do
      add(:donate_member, :boolean, default: false)
      add(:seninor_member, :boolean, default: false)
      add(:sponsor_member, :boolean, default: false)
    end

    create(index(:user_achievements, [:donate_member]))
    create(index(:user_achievements, [:seninor_member]))
    create(index(:user_achievements, [:sponsor_member]))
  end
end
