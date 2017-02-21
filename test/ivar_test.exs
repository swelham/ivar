defmodule IvarTest do
  use ExUnit.Case
  doctest Ivar

  test "new/1 should return a map with the correct http method set" do
    assert Ivar.new(:get)    == %{method: :get}
    assert Ivar.new(:post)   == %{method: :post}
    assert Ivar.new(:put)    == %{method: :put}
    assert Ivar.new(:patch)  == %{method: :patch}
    assert Ivar.new(:delete) == %{method: :delete}
  end

  test "new/2 should return a map with the correct http method and url set" do
    assert Ivar.new(:get,    "http://example.com") == %{method: :get, url: "http://example.com"}
    assert Ivar.new(:post,   "http://example.com") == %{method: :post, url: "http://example.com"}
    assert Ivar.new(:put,    "http://example.com") == %{method: :put, url: "http://example.com"}
    assert Ivar.new(:patch,  "http://example.com") == %{method: :patch, url: "http://example.com"}
    assert Ivar.new(:delete, "http://example.com") == %{method: :delete, url: "http://example.com"}
  end
end
