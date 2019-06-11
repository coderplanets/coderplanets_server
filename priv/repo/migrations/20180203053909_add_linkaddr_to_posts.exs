defmodule GroupherServer.Repo.Migrations.AddLinkaddrToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:link_addr, :string)
    end
  end
end
