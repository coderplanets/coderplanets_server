defmodule MastaniServer.Repo.Migrations.RenameMemberInAchievements do
  use Ecto.Migration

  def change do
    # rename(table(:user_achievements), :seninor_member, to: :senior_member)
    alter table(:user_achievements) do
      add(:senior_member, :boolean, default: false)
    end
  end
end
