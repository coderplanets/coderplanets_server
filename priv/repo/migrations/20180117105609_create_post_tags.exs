defmodule MastaniServer.Repo.Migrations.CreatePostTags do
  use Ecto.Migration

  def change do
    create table(:post_tags) do
      add(:title, :string)
      add(:user_id, references(:users))

      timestamps()
    end
  end
end
