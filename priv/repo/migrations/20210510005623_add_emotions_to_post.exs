defmodule GroupherServer.Repo.Migrations.AddEmotionsToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:emotions, :map)
    end
  end
end
