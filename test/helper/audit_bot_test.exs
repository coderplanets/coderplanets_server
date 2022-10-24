defmodule GroupherServer.Test.Helper.AuditBot do
  @moduledoc false

  use GroupherServerWeb.ConnCase, async: true
  alias Helper.AuditBot

  describe "[general test]" do
    # test "illgal words should be detected" do
    #   {:error, result} = AuditBot.analysis(:text, "<div>M卖批, 这也太操蛋了, 党中央</div>")

    #   assert result == %{
    #            audit_failed: false,
    #            audit_failed_reason: "",
    #            illegal_reason: ["政治敏感", "低俗辱骂"],
    #            illegal_words: ["党中央", "操蛋", "卖批"],
    #            is_legal: false
    #          }
    # end

    # test "legal words should be detected" do
    #   {:ok, result} = AuditBot.analysis(:text, "消灭人类暴政，世界属于三体")

    #   assert result == %{
    #            audit_failed: false,
    #            audit_failed_reason: "",
    #            illegal_reason: [],
    #            illegal_words: [],
    #            is_legal: true
    #          }
    # end
  end
end
