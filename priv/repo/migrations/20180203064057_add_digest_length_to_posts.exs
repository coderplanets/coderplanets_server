defmodule GroupherServer.Repo.Migrations.AddDigestLengthToPosts do
  use Ecto.Migration

  def change do
    alter table(:cms_posts) do
      add(:digest, :string)
      add(:length, :integer)
    end
  end
end
