defmodule GroupherServer.Repo.Migrations.RenameIsCloseToIsConfirmInReports do
  use Ecto.Migration

  def change do
    alter(table(:abuse_reports), do: remove(:is_closed))
    alter(table(:cms_posts), do: remove(:is_reported))
    alter(table(:cms_jobs), do: remove(:is_reported))
    alter(table(:cms_repos), do: remove(:is_reported))
  end
end
