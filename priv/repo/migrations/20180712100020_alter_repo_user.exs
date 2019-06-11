defmodule GroupherServer.Repo.Migrations.AlterRepoUser do
  use Ecto.Migration

  def change do
    alter table(:cms_repo_users) do
      timestamps()
    end
  end
end
