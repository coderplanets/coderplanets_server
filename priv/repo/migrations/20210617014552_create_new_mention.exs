defmodule GroupherServer.Repo.Migrations.CreateNewMention do
  use Ecto.Migration

  def change do
    create table(:mentions) do
      # article or comment
      add(:type, :string)
      add(:article_id, :id)
      add(:title, :string)
      # optional comment id
      add(:comment_id, :id)
      add(:from_user_id, references(:users, on_delete: :nothing), null: false)
      add(:to_user_id, references(:users, on_delete: :nothing), null: false)

      add(:block_linker, {:array, :string})

      add(:read, :boolean, default: false)

      timestamps()
    end

    create(index(:mentions, [:from_user_id]))
    create(index(:mentions, [:to_user_id]))
  end
end
