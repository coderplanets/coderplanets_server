defmodule GroupherServer.CMS.Constant do
  @moduledoc """
  constant used for CMS

  NOTE: DO NOT modify, unless you know what you are doing
  """
  @artiment_legal 0
  @artiment_illegal 1
  @artiment_audit_failed 2

  @community_normal 0
  @community_applying 1

  @apply_public "PUBLIC"
  @apply_city "CITY"
  @apply_works "WORKS"
  @apply_team "TEAM"

  def pending(:legal), do: @artiment_legal
  def pending(:illegal), do: @artiment_illegal
  def pending(:audit_failed), do: @artiment_audit_failed

  def pending(:normal), do: @community_normal
  def pending(:applying), do: @community_applying

  def apply_category(:public), do: @apply_public
  def apply_category(:city), do: @apply_city
  def apply_category(:works), do: @apply_works
  def apply_category(:team), do: @apply_team
end
