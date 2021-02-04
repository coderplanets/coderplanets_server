defmodule GroupherServerWeb.Test.Controller.OG do
  @moduledoc """
  test open-graph fether
  """
  use GroupherServer.TestTools

  test "should return valid structure when query url is valid" do
    conn = build_conn()

    res = get(conn, "/api/og-info", %{url: "https://github.com"})
    res = json_response(res, 200)

    assert Map.has_key?(res, "success")
    assert Map.has_key?(res, "meta")

    meta = res["meta"]
    assert Map.has_key?(meta, "description")
    assert Map.has_key?(meta, "image")
    assert Map.has_key?(meta, "title")

    image = get_in(res, ["meta", "image"])

    assert Map.has_key?(image, "url")
  end

  test "should return valid structure & error msg when query domain is not exsit" do
    conn = build_conn()

    res = get(conn, "/api/og-info", %{url: "https://jfiel.com"})
    res = json_response(res, 200)

    assert Map.has_key?(res, "success")
    assert Map.has_key?(res, "meta")

    success = res["success"]
    assert success == 0

    meta = res["meta"]
    assert Map.has_key?(meta, "description")
    assert Map.has_key?(meta, "image")
    assert Map.has_key?(meta, "title")

    title = get_in(res, ["meta", "title"])
    description = get_in(res, ["meta", "description"])
    assert title == "domain-not-exsit"
    assert description == "--"

    image = get_in(res, ["meta", "image"])

    assert Map.has_key?(image, "url")
  end

  test "return empty valid structure when url not follow open-graph" do
    conn = build_conn()

    url = "https://github.com"
    res = get(conn, "/api/og-info", %{url: url})
    res = json_response(res, 200)

    # IO.inspect(res, label: "json res")
    assert Map.has_key?(res, "success")
    assert Map.has_key?(res, "meta")

    success = res["success"]
    assert success == 1

    meta = res["meta"]
    assert Map.has_key?(meta, "description")
    assert Map.has_key?(meta, "image")
    assert Map.has_key?(meta, "title")

    title = get_in(res, ["meta", "title"])
    assert is_nil(title) == false

    description = get_in(res, ["meta", "description"])
    assert is_nil(description) == false

    image = get_in(res, ["meta", "image"])
    assert Map.has_key?(image, "url")

    assert is_nil(image["url"]) == false
  end

  test "return empty valid structure when title nil but description not nil" do
    conn = build_conn()

    url = "https://zhuanlan.zhihu.com"
    res = get(conn, "/api/og-info", %{url: url})
    res = json_response(res, 200)

    assert Map.has_key?(res, "success")
    assert Map.has_key?(res, "meta")

    success = res["success"]
    assert success == 1

    meta = res["meta"]
    assert Map.has_key?(meta, "description")
    assert Map.has_key?(meta, "image")
    assert Map.has_key?(meta, "title")

    title = get_in(res, ["meta", "title"])
    description = get_in(res, ["meta", "title"])

    assert String.contains?(description, title)

    image = get_in(res, ["meta", "image"])
    assert Map.has_key?(image, "url")
    assert image["url"] == nil
  end
end
