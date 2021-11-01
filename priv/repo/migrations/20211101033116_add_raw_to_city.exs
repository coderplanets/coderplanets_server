defmodule GroupherServer.Repo.Migrations.AddRawToCity do
  use Ecto.Migration

  def change do
    rename(table(:cms_cities), :link, to: :raw)
  end
end
