defmodule GroupherServer.Repo.Migrations.AddLinkIconToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:link_icon, :string)
    end
  end
end
