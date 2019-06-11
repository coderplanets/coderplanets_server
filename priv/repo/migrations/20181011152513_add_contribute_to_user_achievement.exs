defmodule GroupherServer.Repo.Migrations.AddContributeToUserAchievement do
  use Ecto.Migration

  def change do
    alter table(:user_achievements) do
      add(
        :source_contribute,
        :map,
        default: %{web: false, server: false, mobile: false, we_app: false, h5: false}
      )
    end
  end
end
