defmodule GroupherServer.Repo.Migrations.AddLinkToDrink do
  use Ecto.Migration

  def change do
    alter table(:cms_drinks) do
      add(:link_addr, :string)
    end
  end
end
