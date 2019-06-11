defmodule GroupherServer.Repo.Migrations.AddExtraInfoToGithubUsers do
  use Ecto.Migration

  def change do
    alter table(:github_users) do
      add(:access_token, :string)
      add(:node_id, :string)
    end

    create(unique_index(:github_users, [:node_id]))
  end
end
