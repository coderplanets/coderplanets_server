defmodule GroupherServer.Repo.Migrations.AddCopyrightToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:copy_right, :string, default: "original")
    end
  end
end
