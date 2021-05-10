defmodule GroupherServer.CMS.Delegate.Helper do
  @moduledoc """
  helpers for GroupherServer.CMS.Delegate
  """
  import Helper.Utils, only: [get_config: 2, done: 1]

  alias GroupherServer.{Accounts, Repo}
  alias Accounts.User

  # TODO:
  # @max_latest_emotion_users_count ArticleComment.max_latest_emotion_users_count()
  @max_latest_emotion_users_count 4
  @supported_emotions get_config(:article, :supported_emotions)
  @supported_comment_emotions get_config(:article, :comment_supported_emotions)

  defp get_supported_mentions(:comment), do: @supported_comment_emotions
  defp get_supported_mentions(_), do: @supported_emotions

  def mark_viewer_emotion_states(paged_contents, nil), do: paged_contents
  def mark_viewer_emotion_states(paged_contents, nil, :comment), do: paged_contents
  def mark_viewer_emotion_states(%{entries: []} = paged_contents, _), do: paged_contents

  @doc """
  mark viewer emotions status for article or comment
  """
  def mark_viewer_emotion_states(
        %{entries: entries} = paged_contents,
        %User{} = user,
        type \\ :article
      ) do
    IO.inspect("hello?")
    supported_emotions = get_supported_mentions(type)

    new_entries =
      Enum.map(entries, fn article ->
        update_viewed_status =
          supported_emotions
          |> Enum.reduce([], fn emotion, acc ->
            already_emotioned = user_in_logins?(article.emotions[:"#{emotion}_user_logins"], user)
            acc ++ ["viewer_has_#{emotion}ed": already_emotioned]
          end)
          |> Enum.into(%{})

        updated_emotions = Map.merge(article.emotions, update_viewed_status)
        Map.put(article, :emotions, updated_emotions)
      end)

    %{paged_contents | entries: new_entries}
  end

  @doc """
  update emotions field for boty article and comment
  """
  def update_emotions_field(content, emotion, status, user) do
    %{user_count: user_count, user_list: user_list} = status

    emotions =
      %{}
      |> Map.put(:"#{emotion}_count", user_count)
      |> Map.put(:"#{emotion}_user_logins", user_list |> Enum.map(& &1.login))
      |> Map.put(
        :"latest_#{emotion}_users",
        Enum.slice(user_list, 0, @max_latest_emotion_users_count)
      )

    viewer_has_emotioned = user.login in Map.get(emotions, :"#{emotion}_user_logins")
    emotions = emotions |> Map.put(:"viewer_has_#{emotion}ed", viewer_has_emotioned)

    content
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_embed(:emotions, emotions)
    |> Repo.update()
    # virtual field can not be updated
    |> add_viewer_emotioned_ifneed(emotions)
    |> done
  end

  defp add_viewer_emotioned_ifneed({:error, error}, _), do: {:error, error}

  defp add_viewer_emotioned_ifneed({:ok, comment}, emotions) do
    Map.merge(comment, %{emotion: emotions})
  end

  defp user_in_logins?([], _), do: false
  defp user_in_logins?(ids_list, %User{login: login}), do: Enum.member?(ids_list, login)
end
