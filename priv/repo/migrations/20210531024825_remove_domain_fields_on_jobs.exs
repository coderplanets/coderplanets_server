defmodule GroupherServer.Repo.Migrations.RemoveDomainFieldsOnJobs do
  use Ecto.Migration

  def change do
    alter(table(:cms_jobs), do: remove(:salary))
    alter(table(:cms_jobs), do: remove(:exp))
    alter(table(:cms_jobs), do: remove(:education))
    alter(table(:cms_jobs), do: remove(:field))
    alter(table(:cms_jobs), do: remove(:finance))
    alter(table(:cms_jobs), do: remove(:scale))

    alter(table(:cms_jobs), do: remove(:company_logo))
  end
end
