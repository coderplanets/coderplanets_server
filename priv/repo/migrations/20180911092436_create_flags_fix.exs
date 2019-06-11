defmodule GroupherServer.Repo.Migrations.CreateFlags do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:flags) do
      timestamps()
    end
  end
end
