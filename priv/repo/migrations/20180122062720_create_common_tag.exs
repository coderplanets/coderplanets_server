defmodule GroupherServer.Repo.Migrations.CreateCommonTag do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add(:community, :string)
      add(:part, :string)
      add(:title, :string)
      add(:color, :string)
      add(:user_id, references(:users))

      timestamps()
    end

    create(unique_index(:tags, [:community, :part, :title]))
  end
end
