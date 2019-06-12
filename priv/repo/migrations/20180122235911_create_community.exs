defmodule GroupherServer.Repo.Migrations.CreateCommunity do
  use Ecto.Migration

  def change do
    create table(:communities) do
      add(:title, :string)
      add(:desc, :string)
      add(:author, references(:users))
    end

    create(unique_index(:communities, [:title]))
  end
end
