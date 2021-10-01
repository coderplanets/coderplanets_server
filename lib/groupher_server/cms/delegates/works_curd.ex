defmodule GroupherServer.CMS.Delegate.WorksCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [strip_struct: 1, done: 1]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.ArticleCURD, only: [create_article: 4]

  # import Helper.ErrorCode
  # import ShortMaps

  # alias Helper.{ORM}
  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.{Community, Techstack}
  alias Accounts.Model.User

  alias Helper.ORM

  # works can only be published on home community
  def create_works(%{techstacks: techstacks} = attrs, %User{} = user) do
    with {:ok, home_community} <- ORM.find_by(Community, %{raw: "home"}),
         {:ok, works} <- create_article(home_community, :works, attrs, user),
         {:ok, techstacks} <- get_or_create_techstacks(techstacks) do
      works = Repo.preload(works, :techstacks)

      works
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:techstacks, works.techstacks ++ techstacks)
      |> Ecto.Changeset.put_embed(:social_info, Map.get(attrs, :social_info, []))
      |> Ecto.Changeset.put_embed(:app_store, Map.get(attrs, :app_store, []))
      |> Repo.update()
    end

    # create_article
    # create_article(community, :works, attrs, user)

    # 1. make sure Techstack exists
    # 2. create works

    # works
    # |> Ecto.Changeset.change()
    # |> Ecto.Changeset.put_assoc(:techstacks, works.communities ++ [techstack])
    # |> Repo.update()
  end

  defp get_or_create_techstacks(techstacks) do
    techstacks
    |> Enum.map(&String.downcase(&1))
    |> Enum.reduce([], fn title, acc ->
      with {:ok, techstack} <- get_techstack(title) do
        acc ++ [techstack]
      end
    end)
    |> done
  end

  defp get_techstack(title) do
    case ORM.find_by(Techstack, %{title: title}) do
      {:error, _} -> create_techstack(title)
      {:ok, techstack} -> {:ok, techstack}
    end
  end

  defp create_techstack(title) do
    attrs =
      case ORM.find_by(Community, %{raw: title}) do
        {:ok, community} ->
          %{
            title: community.title,
            logo: community.logo,
            community_link: "/#{community.raw}",
            desc: community.desc
          }

        {:error, _} ->
          %{title: title}
      end

    ORM.create(Techstack, attrs)
  end
end
