defmodule MastaniServer.CMS.Delegate.CommunityOperation do
  import ShortMaps
  import Helper.ErrorCode
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
    Thread,
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
  unset a category to community
  """
  def unset_category(%Community{id: community_id}, %Category{id: category_id}) do
    with {:ok, community_category} <-
           CommunityCategory |> ORM.findby_delete(~m(community_id category_id)a) do
      Community |> ORM.find(community_category.community_id)
    end
  end

  @doc """
  set to thread to a community
  """
  def set_thread(%Community{id: community_id}, %Thread{id: thread_id}) do
    with {:ok, community_thread} <- CommunityThread |> ORM.create(~m(community_id thread_id)a) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  unset to thread to a community
  """
  def unset_thread(%Community{id: community_id}, %Thread{id: thread_id}) do
    with {:ok, community_thread} <-
           CommunityThread |> ORM.findby_delete(~m(community_id thread_id)a) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  set a community editor
  """
  def set_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
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
    |> set_editor_result()
  end

  @doc """
  unset a community editor
  """
  def unset_editor(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, _} <- ORM.findby_delete(CommunityEditor, ~m(user_id community_id)a),
         {:ok, _} <- PassportCURD.delete_passport(%Accounts.User{id: user_id}) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  defp set_editor_result({:ok, %{insert_editor: editor}}) do
    Accounts.User |> ORM.find(editor.user_id)
  end

  defp set_editor_result({:error, :stamp_passport, _result, _steps}),
    do: {:error, "stamp passport error"}

  defp set_editor_result({:error, :insert_editor, _result, _steps}),
    do: {:error, "insert editor error"}

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  def subscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      Community |> ORM.find(record.community_id)
    end
  end

  def code2err({:error, error}, code) do
    {:error, message: error, code: ecode(code)}
  end

  def unsubscribe_community(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community_id, user_id: user_id) do
      Community |> ORM.find(record.community_id)
    end
  end
end
