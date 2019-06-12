defmodule GroupherServer.Repo.Migrations.CreateCmsPassports do
  use Ecto.Migration

  def change do
    create table(:cms_passports) do
      add(:roles, :map)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:cms_passports, [:user_id]))
  end
end
