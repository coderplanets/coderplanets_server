defmodule MastaniServer.Repo.Migrations.RemoveUserPostJoinTable do
  use Ecto.Migration

  def change do
    drop(table("users_posts"))
  end
end
