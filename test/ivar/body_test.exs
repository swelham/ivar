defmodule IvarTest.Body do
  use ExUnit.Case, async: true
  doctest Ivar.Body

  alias Ivar.Body
  alias Ivar.Files
  
  test "put/3 should put body for a mime extension" do
    result = Body.put(%{}, "some text", "text")
    
    assert result == %{body: {"text/plain", {"content-type", "text/plain"}, "some text"}}
  end
  
  test "put/3 should put body for custom mime type" do
    result = Body.put(%{}, "some content", "custom/type")
  
    assert result == %{body: {"custom/type", {"content-type", "custom/type"}, "some content"}}
  end
  
  test "put/3 should encode and put body for known type: json" do
    result = Body.put(%{}, %{some: "content"}, :json)
    
    assert result == %{body: {:json, {"content-type", "application/json"}, "{\"some\":\"content\"}"}}
  end
  
  test "put/3 should encode and put body for known type: url_encoded" do
    data = %{some: "content", abc: 123}
    
    result = Body.put(%{}, data, :url_encoded)
    
    assert result == %{body: {:url_encoded, {"content-type", "application/x-www-form-urlencoded"}, "abc=123&some=content"}}
  end
  
  test "put/3 should put binary content content for known types" do
    assert Body.put(%{}, "{\"some\":\"data\"}", :json) ==
      %{body: {:json, {"content-type", "application/json"}, "{\"some\":\"data\"}"}}
      
    assert Body.put(%{}, "some=data", :url_encoded) ==
      %{body: {:url_encoded, {"content-type", "application/x-www-form-urlencoded"}, "some=data"}}
  end
  
  test "put/3 should put :url_encoded body when request has files attached" do
    data = %{some: "content"}
    
    result = %{}
    |> Files.put({"test", "", "test.jpg", "jpg"})
    |> Body.put(data, :url_encoded)
    
    assert result.body == {:url_encoded, {"content-type", "application/x-www-form-urlencoded"}, "some=content"}
  end
  
  test "put/3 should return error when putting non :url_encoded body when request has files attached" do
    data = %{some: "content"}
    
    result = %{}
    |> Files.put({"test", "", "test.jpg", "jpg"})
    |> Body.put(data, :json)
    
    assert result == {:error, "Body must be of type :url_encoded when files are attached"}
  end
end