defmodule GroupherServer.Repo.Migrations.AddMetaToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:meta, :map)
    end
  end
end
