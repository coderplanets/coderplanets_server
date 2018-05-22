defmodule MastaniServer.CMS.Delegate.CommunityOperation do
  import ShortMaps
  # import MastaniServer.CMS.Utils.Matcher

  alias MastaniServer.CMS.Delegate.PassportCURD
  alias MastaniServer.{Repo, Accounts}
  alias Helper.{ORM, Certification}
  alias Ecto.Multi

  alias MastaniServer.CMS.{
    # Author,
    CommunityThread,
    CommunityEditor,
    Community,
    Category,
    CommunityCategory,
    CommunitySubscriber
    # CommunityEditor
  }

  @doc """
  set a category to community
  """
  def set_category(%Community{id: community_id}, %Category{id: category_id}) do
    with {:ok, community_category} <-
           CommunityCategory |> ORM.create(~m(community_id category_id)a) do
      Community |> ORM.find(community_category.community_id)
    end
  end

  @doc """
  add_thread_to_community
  """
  def add_thread_to_community(attrs) do
    with {:ok, community_thread} <- CommunityThread |> ORM.create(attrs) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  set a community editor
  """
  def add_editor_to_community(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    Multi.new()
    |> Multi.insert(
      :insert_editor,
      CommunityEditor.changeset(%CommunityEditor{}, ~m(user_id community_id title)a)
    )
    |> Multi.run(:stamp_passport, fn _ ->
      rules = Certification.passport_rules(cms: title)
      PassportCURD.stamp_passport(%Accounts.User{id: user_id}, rules)
    end)
    |> Repo.transaction()
    |> add_editor_result()
  end

  defp add_editor_result({:ok, %{insert_editor: editor}}) do
    Accounts.User |> ORM.find(editor.user_id)
  end

  defp add_editor_result({:error, :stamp_passport, _result, _steps}),
    do: {:error, "stamp passport error"}

  defp add_editor_result({:error, :insert_editor, _result, _steps}),
    do: {:error, "insert editor error"}

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  def subscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      Community |> ORM.find(record.community_id)
    end
  end

  def unsubscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community_id, user_id: user_id) do
      Community |> ORM.find(record.community_id)
    end
  end
end
