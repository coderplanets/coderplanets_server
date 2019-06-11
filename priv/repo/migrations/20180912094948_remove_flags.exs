defmodule GroupherServer.Repo.Migrations.RemoveFlags do
  use Ecto.Migration

  def change do
    drop(table(:flags))
  end
end
