defmodule GroupherServer.Repo.Migrations.AddOnTopToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:pin, :boolean, default: false)
    end

    create(index(:cms_posts, [:pin]))
  end
end
