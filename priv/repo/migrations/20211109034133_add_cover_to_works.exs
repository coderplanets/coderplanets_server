defmodule GroupherServer.Repo.Migrations.AddCoverToWorks do
  use Ecto.Migration

  def change do
    alter table(:cms_works) do
      add(:cover, :string)
    end
  end
end
