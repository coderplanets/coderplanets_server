defmodule GroupherServer.Repo.Migrations.AddEmotionsToRepo do
  use Ecto.Migration

  def change do
    alter table(:cms_repos) do
      add(:emotions, :map)
    end
  end
end
