defmodule GroupherServer.Repo.Migrations.MissingBodyToBlog do
  use Ecto.Migration

  def change do
    alter(table(:cms_blogs), do: add(:body, :string))
  end
end
