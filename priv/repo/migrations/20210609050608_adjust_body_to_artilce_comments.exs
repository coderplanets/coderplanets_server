defmodule GroupherServer.Repo.Migrations.AdjustBodyToArtilceComments do
  use Ecto.Migration

  def change do
    alter table(:articles_comments) do
      modify(:body_html, :text)
      add(:body, :text)
    end
  end
end
