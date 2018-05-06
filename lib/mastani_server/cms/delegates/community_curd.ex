defmodule MastaniServer.CMS.Delegate.CommunityCURD do
  # TODO docs:  include community / editors / curd
  import Ecto.Query, warn: false
  import Helper.Utils, only: [deep_merge: 2]
  import ShortMaps

  alias MastaniServer.{Repo, Accounts}

  alias MastaniServer.CMS.{
    Community,
    CommunityEditor
  }

  alias MastaniServer.CMS.Delegate.Passport

  alias Helper.{ORM, Certification}
  alias Ecto.Multi

  def create_community(attrs), do: Community |> ORM.create(attrs)

  @doc """
  set a community editor
  """
  def add_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    Multi.new()
    |> Multi.insert(
      :insert_editor,
      CommunityEditor.changeset(%CommunityEditor{}, ~m(user_id community_id title)a)
    )
    |> Multi.run(:stamp_passport, fn _ ->
      rules = Certification.passport_rules(cms: title)
      Passport.stamp_passport(%Accounts.User{id: user_id}, rules)
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

  def update_editor(%Accounts.User{id: user_id}, %Community{id: community_id}, title) do
    clauses = ~m(user_id community_id)a

    with {:ok, _} <- CommunityEditor |> ORM.update_by(clauses, ~m(title)a) do
      Accounts.User |> ORM.find(user_id)
    end
  end

  def delete_editor(%Accounts.User{id: user_id}, %Community{id: community_id}) do
    with {:ok, _} <- ORM.findby_delete(CommunityEditor, ~m(user_id community_id)a),
         {:ok, _} <- Passport.delete_passport(%Accounts.User{id: user_id}) do
      Accounts.User |> ORM.find(user_id)
    end
  end
end
