defmodule GroupherServer.Repo.Migrations.AddTrashFlagToPost do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:trash, :boolean, default: false)
    end

    create(index(:cms_posts, [:trash]))
  end
end
