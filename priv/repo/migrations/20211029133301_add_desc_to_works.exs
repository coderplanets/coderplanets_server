defmodule GroupherServer.Repo.Migrations.AddDescToWorks do
  use Ecto.Migration

  def change do
    alter table(:cms_works) do
      add(:desc, :string)
    end
  end
end
