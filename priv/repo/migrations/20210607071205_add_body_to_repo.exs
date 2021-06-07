defmodule GroupherServer.Repo.Migrations.AddBodyToRepo do
  use Ecto.Migration

  def change do
    alter(table(:cms_repos), do: add(:body, :string))
    alter(table(:cms_repos), do: add(:digest, :string))
  end
end
