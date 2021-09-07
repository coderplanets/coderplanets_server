defmodule GroupherServer.Repo.Migrations.AddLinkToGuides do
  use Ecto.Migration

  def change do
    alter table(:cms_guides) do
      add(:link_addr, :string)
    end
  end
end
