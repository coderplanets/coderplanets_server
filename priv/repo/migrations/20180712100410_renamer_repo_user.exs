defmodule GroupherServer.Repo.Migrations.RenamerRepoUser do
  use Ecto.Migration

  def change do
    rename(table("cms_repo_users"), to: table("cms_repo_builders"))
  end
end
