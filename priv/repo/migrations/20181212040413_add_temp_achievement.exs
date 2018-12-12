defmodule MastaniServer.Repo.Migrations.AddTempAchievement do
  use Ecto.Migration

  def change do
    alter table(:user_achievements) do
      add(:seninor_member, :boolean, default: false)
    end
  end
end
