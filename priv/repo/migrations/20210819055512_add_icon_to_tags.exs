defmodule GroupherServer.Repo.Migrations.AddIconToTags do
  use Ecto.Migration

  def change do
    alter table(:article_tags) do
      add(:icon, :string)
    end
  end
end
