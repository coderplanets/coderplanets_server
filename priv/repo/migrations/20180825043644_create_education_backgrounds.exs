defmodule GroupherServer.Repo.Migrations.CreateEducationBackgrounds do
  use Ecto.Migration

  def change do
    create table(:education_backgrounds) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:school, :string)
      add(:major, :string)
    end

    create(unique_index(:education_backgrounds, [:user_id]))
  end
end
