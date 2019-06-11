defmodule GroupherServer.Repo.Migrations.AlterRepoAttrs do
  use Ecto.Migration

  def change do
    rename(table(:cms_repos), :title, to: :repo_name)

    alter table(:cms_repos) do
      remove(:repo_author)
    end
  end
end
