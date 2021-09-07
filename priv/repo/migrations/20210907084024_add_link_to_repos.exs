defmodule GroupherServer.Repo.Migrations.AddLinkToRepos do
  use Ecto.Migration

  def change do
    alter table(:cms_repos) do
      add(:link_addr, :string)
    end
  end
end
