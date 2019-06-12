defmodule GroupherServer.Repo.Migrations.AddMoreCustomization do
  use Ecto.Migration

  def change do
    alter table(:customizations) do
      add(:banner_layout, :string)
      add(:contents_layout, :string)
      add(:content_divider, :boolean)
      add(:mark_viewed, :boolean)
      add(:display_density, :string)
    end
  end
end
