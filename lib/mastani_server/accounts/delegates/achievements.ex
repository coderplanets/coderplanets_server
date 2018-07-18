defmodule MastaniServer.Accounts.Delegate.Achievements do
  @moduledoc """
  user achievements related
  acheiveements formula:
  1. create content been stared by other user + 1
  2. create content been watched by other user + 1
  3. create content been favorited by other user + 2
  4. followed by other user + 3
  """
  @content_stared_weight 1
  @content_watched_weight 1
  @content_favorited_weight 2
  @followed_weight 3
end
