defmodule GroupherServer.CMS.Constant do
  @moduledoc """
  constant used for CMS

  NOTE: DO NOT modify, unless you know what you are doing
  """
  @artiment_legal 0
  @artiment_illegal 1
  @artiment_audit_failed 2

  def pending(:legal), do: @artiment_legal
  def pending(:illegal), do: @artiment_illegal
  def pending(:audit_failed), do: @artiment_audit_failed
end
