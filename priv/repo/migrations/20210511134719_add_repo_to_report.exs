defmodule GroupherServer.Repo.Migrations.AddRepoToReport do
  use Ecto.Migration

  def change do
    alter table(:abuse_reports) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end
  end
end
