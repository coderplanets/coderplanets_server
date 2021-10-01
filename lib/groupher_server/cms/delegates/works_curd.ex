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
  alias CMS.Model.{Community, Techstack, City}
  alias Accounts.Model.User

  alias Helper.ORM

  # works can only be published on home community
  def create_works(attrs, %User{} = user) do
    techstacks = Map.get(attrs, :techstacks, [])
    cities = Map.get(attrs, :cities, [])

    with {:ok, home_community} <- ORM.find_by(Community, %{raw: "home"}),
         {:ok, works} <- create_article(home_community, :works, attrs, user),
         {:ok, techstacks} <- get_or_create_techstacks(techstacks),
         {:ok, cities} <- get_or_create_cities(cities) do
      works = Repo.preload(works, [:techstacks, :cities])

      works
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:techstacks, works.techstacks ++ techstacks)
      |> Ecto.Changeset.put_assoc(:cities, works.cities ++ cities)
      |> Ecto.Changeset.put_embed(:social_info, Map.get(attrs, :social_info, []))
      |> Ecto.Changeset.put_embed(:app_store, Map.get(attrs, :app_store, []))
      |> Repo.update()
    end
  end

  defp get_or_create_cities(cities) do
    cities
    |> Enum.map(&String.downcase(&1))
    |> Enum.reduce([], fn title, acc ->
      with {:ok, city} <- get_city(title) do
        acc ++ [city]
      end
    end)
    |> done
  end

  defp get_city(title) do
    case ORM.find_by(City, %{title: title}) do
      {:error, _} -> create_city(title)
      {:ok, city} -> {:ok, city}
    end
  end

  defp create_city(title) do
    attrs =
      case ORM.find_by(Community, %{raw: title}) do
        {:ok, community} ->
          %{
            title: community.title,
            logo: community.logo,
            desc: community.desc,
            link: "/#{community.raw}"
          }

        {:error, _} ->
          %{title: title}
      end

    ORM.create(City, attrs)
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
