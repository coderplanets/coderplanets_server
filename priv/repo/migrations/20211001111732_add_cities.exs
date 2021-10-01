defmodule GroupherServer.Repo.Migrations.AddCities do
  use Ecto.Migration

  def change do
    create table(:cms_cities) do
      add(:title, :string)
      add(:logo, :string)
      add(:desc, :string)
      add(:link, :string)

      timestamps()
    end
  end
end
