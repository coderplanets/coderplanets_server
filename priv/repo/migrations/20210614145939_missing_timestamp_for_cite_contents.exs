defmodule GroupherServer.Repo.Migrations.MissingTimestampForCiteContents do
  use Ecto.Migration

  def change do
    alter table(:cited_contents) do
      timestamps()
    end
  end
end
