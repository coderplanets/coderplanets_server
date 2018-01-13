defmodule MastaniServer.Repo.Migrations.AddViewsToCmsPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      remove(:viewsCount)
      add(:views, :integer, default: 0)
    end
  end
end
