defmodule GroupherServer.Repo.Migrations.CreateTopicForContents do
  use Ecto.Migration

  def change do
    create table(:topics) do
      # add(:community_id, references(:communities, on_delete: :delete_all), null: false)
      # add(:user_id, references(:users))
      add(:thread, :string)
      add(:title, :string, default: "index")
      add(:raw, :string, default: "index")

      timestamps()
    end

    # create(unique_index(:topics, [:community, :part, :title]))
  end
end
