defmodule MastaniServer.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:cms_comments) do
      add :body, :string

      timestamps()
    end
  end
end
