defmodule GroupherServer.Repo.Migrations.CreateCmsPosts do
  use Ecto.Migration

  def change do
    create table(:cms_posts) do
      add(:title, :string)
      add(:desc, :text)
      add(:body, :text)

      timestamps()
    end
  end
end
