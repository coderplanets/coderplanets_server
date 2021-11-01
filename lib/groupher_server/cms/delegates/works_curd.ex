defmodule GroupherServer.CMS.Delegate.WorksCURD do
  @moduledoc """
  CURD operation on post/job ...
  """
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1, atom_values_to_upcase: 1]
  import Helper.ErrorCode

  import GroupherServer.CMS.Delegate.ArticleCURD, only: [create_article: 4, update_article: 2]

  alias GroupherServer.{Accounts, CMS, Repo}
  alias CMS.Model.{Community, Techstack, City, Works}
  alias Accounts.Model.User

  alias Helper.ORM
  alias Ecto.Multi

  # works can only be published on home community
  def create_works(attrs, %User{} = user) do
    attrs = attrs |> atom_values_to_upcase

    with {:ok, home_community} <- ORM.find_by(Community, %{raw: "home"}) do
      Multi.new()
      |> Multi.run(:create_works, fn _, _ ->
        create_article(home_community, :works, attrs, user)
      end)
      |> Multi.run(:update_works_fields, fn _, %{create_works: works} ->
        update_works_fields(works, attrs)
      end)
      |> Repo.transaction()
      |> result()
    end
  end

  def update_works(%Works{} = works, attrs) do
    attrs = attrs |> atom_values_to_upcase

    Multi.new()
    |> Multi.run(:update_works, fn _, _ ->
      update_article(works, attrs)
    end)
    |> Multi.run(:update_works_fields, fn _, %{update_works: works} ->
      update_works_fields(works, attrs)
    end)
    |> Repo.transaction()
    |> result()
  end

  # update works spec fields
  defp update_works_fields(%Works{} = works, attrs) do
    works = Repo.preload(works, [:techstacks, :cities])

    desc = Map.get(attrs, :desc, works.desc)
    home_link = Map.get(attrs, :home_link, works.home_link)
    techstacks = Map.get(attrs, :techstacks, works.techstacks)
    cities = Map.get(attrs, :cities, works.cities)
    social_info = Map.get(attrs, :social_info, works.social_info)
    app_store = Map.get(attrs, :app_store, works.app_store)

    with {:ok, techstacks} <- get_or_create_techstacks(techstacks),
         {:ok, cities} <- get_or_create_cities(cities) do
      works
      |> Ecto.Changeset.change(%{desc: desc, home_link: home_link})
      |> Ecto.Changeset.put_assoc(:techstacks, uniq_by_raw(techstacks))
      |> Ecto.Changeset.put_assoc(:cities, uniq_by_raw(cities))
      |> Ecto.Changeset.put_embed(:social_info, social_info)
      |> Ecto.Changeset.put_embed(:app_store, app_store)
      |> Repo.update()
    end
  end

  defp get_or_create_cities([]), do: {:ok, []}

  defp get_or_create_cities(cities) do
    cities
    |> Enum.map(&String.downcase(&1))
    |> Enum.reduce([], fn title, acc ->
      with {:ok, city} <- get_city(title) do
        acc ++ [city]
      end
    end)
    |> uniq_by_raw
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
            raw: community.raw
          }

        {:error, _} ->
          %{title: title}
      end

    ORM.create(City, attrs)
  end

  defp get_or_create_techstacks([]), do: {:ok, []}

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
            raw: community.raw,
            logo: community.logo,
            community_link: "/#{community.raw}",
            desc: community.desc
          }

        {:error, _} ->
          %{title: title, raw: String.downcase(title)}
      end

    ORM.create(Techstack, attrs)
  end

  defp uniq_by_raw(list) do
    Enum.uniq_by(list, & &1.raw)
  end

  # defp result({:ok, %{create_works: result}}), do: {:ok, result}
  defp result({:ok, %{update_works_fields: result}}), do: {:ok, result}
  defp result({:ok, %{update_works: result}}), do: {:ok, result}

  defp result({:error, :create_works, _result, _steps}) do
    {:error, [message: "create works", code: ecode(:create_fails)]}
  end

  defp result({:error, :update_works_fields, _result, _steps}) do
    {:error, [message: "update works fields", code: ecode(:create_fails)]}
  end

  defp result({:error, :update_works, _result, _steps}) do
    {:error, [message: "update works", code: ecode(:update_fails)]}
  end
end
