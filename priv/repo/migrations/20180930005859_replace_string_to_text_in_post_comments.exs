defmodule GroupherServer.Repo.Migrations.ReplaceStringToTextInPostComments do
  use Ecto.Migration

  def change do
    alter table(:posts_comments) do
      remove(:body)
      add(:body, :text)
    end
  end
end
