defmodule GroupherServer.Repo.Migrations.CreateCmsJobs do
  use Ecto.Migration

  def change do
    create table(:cms_jobs) do
      add(:title, :string)
      add(:company, :string)
      add(:bonus, :string)
      add(:company_logo, :string)
      add(:location, :string)
      add(:desc, :text)
      add(:body, :text)
      add(:author_id, references(:cms_authors, on_delete: :delete_all), null: false)
      add(:views, :integer, default: 0)
      add(:link_addr, :string)
      add(:link_source, :string)
      add(:min_salary, :integer, default: 0)
      add(:max_salary, :integer, default: 10_000_000)
      add(:min_experience, :integer, default: 1)
      add(:max_experience, :integer, default: 3)
      add(:min_education, :string)
      add(:digest, :string)
      add(:length, :integer)

      timestamps()
    end

    create(index(:cms_jobs, [:author_id]))
  end
end
