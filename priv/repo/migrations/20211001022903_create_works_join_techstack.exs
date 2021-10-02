defmodule GroupherServer.Repo.Migrations.CreateWorksJoinTechstack do
  use Ecto.Migration

  def change do
    create table(:works_join_techstacks) do
      add(:works_id, references(:cms_works, on_delete: :delete_all), null: false)
      add(:techstack_id, references(:cms_techstacks, on_delete: :delete_all), null: false)
    end

    create(unique_index(:works_join_techstacks, [:works_id, :techstack_id]))
  end
end
