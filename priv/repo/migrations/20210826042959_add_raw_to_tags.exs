defmodule GroupherServer.Repo.Migrations.AddRawToTags do
  use Ecto.Migration

  def change do
    alter table(:article_tags) do
      add(:raw, :string)
    end
  end
end
