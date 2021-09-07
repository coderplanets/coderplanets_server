defmodule GroupherServer.Repo.Migrations.AddLinkToWorks do
  use Ecto.Migration

  def change do
    alter table(:cms_works) do
      add(:link_addr, :string)
    end
  end
end
