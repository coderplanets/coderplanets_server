defmodule GroupherServer.Repo.Migrations.RenameMentionsTypeToThread do
  use Ecto.Migration

  def change do
    rename(table(:mentions), :type, to: :thread)
  end
end
