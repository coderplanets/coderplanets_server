defmodule GroupherServer.Repo.Migrations.MissingTimestampToBlogs do
  use Ecto.Migration

  def change do
    alter table(:cms_blogs) do
      timestamps()
    end
  end
end
