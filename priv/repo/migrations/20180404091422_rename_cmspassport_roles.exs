defmodule GroupherServer.Repo.Migrations.RenameCmspassportRoles do
  use Ecto.Migration

  def change do
    rename(table(:cms_passports), :roles, to: :rules)
  end
end
