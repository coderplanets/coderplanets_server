defmodule GroupherServer.Repo.Migrations.CreateWorksTechstack do
  use Ecto.Migration

  def change do
    create table(:cms_techstacks) do
      add(:title, :string)
      add(:logo, :string)
      add(:desc, :string)
      add(:home_link, :string)
      add(:community_link, :string)
      add(:category, :string)

      timestamps()
    end
  end
end
