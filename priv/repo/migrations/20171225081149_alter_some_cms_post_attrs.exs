defmodule MastaniServer.Repo.Migrations.AlterSomeCmsPostAttrs do
  use Ecto.Migration

  def up do
    alter table(:cms_posts) do
      remove(:viewerCanCollect)
      remove(:viewerCanWatch)

      add(:viewerCanCollect, :boolean, default: false, null: false)
      add(:viewerCanWatch, :boolean, default: false, null: false)
    end
  end

  def down do
    alter table(:cms_posts) do
      modify(:viewerCanCollect, :string)
      modify(:viewerCanWatch, :string)
    end
  end
end
