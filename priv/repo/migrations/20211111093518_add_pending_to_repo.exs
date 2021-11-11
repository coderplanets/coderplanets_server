defmodule GroupherServer.Repo.Migrations.AddPendingToRepo do
  use Ecto.Migration

  def change do
    alter(table(:cms_repos), do: add(:pending, :integer, default: 0))
  end
end
