defmodule GroupherServer.Repo.Migrations.RemoveEducationCompanyInUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:company)
      remove(:education)
    end
  end
end
