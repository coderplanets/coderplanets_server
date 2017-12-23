defmodule MastaniServer.CMS.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias MastaniServer.CMS.Post


  schema "cms_posts" do
    field :body, :string
    field :isRefined, :boolean, default: false
    field :isSticky, :boolean, default: false
    field :title, :string
    field :viewerCanCollect, :string
    field :viewerCanStar, :boolean, default: false
    field :viewerCanWatch, :string
    field :viewsCount, :integer

    timestamps()
  end

  @doc false
  def changeset(%Post{} = post, attrs) do
    post
    |> cast(attrs, [:title, :body, :viewsCount, :isRefined, :isSticky, :viewerCanStar, :viewerCanWatch, :viewerCanCollect])
    |> validate_required([:title, :body, :viewsCount, :isRefined, :isSticky, :viewerCanStar, :viewerCanWatch, :viewerCanCollect])
  end
end
