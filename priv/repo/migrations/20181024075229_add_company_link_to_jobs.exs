defmodule GroupherServer.Repo.Migrations.AddCompanyLinkToJobs do
  use Ecto.Migration

  def change do
    alter table(:cms_jobs) do
      add(:company_link, :string)
    end
  end
end
