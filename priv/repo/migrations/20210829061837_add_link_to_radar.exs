defmodule GroupherServer.Repo.Migrations.AddLinkToRadar do
  use Ecto.Migration

  def change do
    alter table(:cms_radars) do
      add(:link_addr, :string)
    end
  end
end
