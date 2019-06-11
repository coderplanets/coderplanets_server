defmodule GroupherServer.Repo.Migrations.AlterJobFields do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      remove(:min_salary)
      remove(:max_salary)
      remove(:min_experience)
      remove(:max_experience)
      remove(:min_education)
      remove(:link_source)
      remove(:bonus)

      add(:salary, :string)
      add(:exp, :string)
      add(:education, :string)
      add(:field, :string)
    end
  end
end
