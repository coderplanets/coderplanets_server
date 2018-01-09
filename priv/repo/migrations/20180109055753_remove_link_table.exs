defmodule MastaniServer.Repo.Migrations.RemoveLinkTable do
  use Ecto.Migration

  def change do
    drop(table("links"))
  end
end
