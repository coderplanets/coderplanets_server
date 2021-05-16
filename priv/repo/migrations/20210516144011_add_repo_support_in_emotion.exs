defmodule GroupherServer.Repo.Migrations.AddRepoSupportInEmotion do
  use Ecto.Migration

  def change do
    alter table(:articles_users_emotions) do
      add(:repo_id, references(:cms_repos, on_delete: :delete_all))
    end
  end
end
