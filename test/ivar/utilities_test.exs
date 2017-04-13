defmodule IvarTest.Utilities do
  use ExUnit.Case, async: true
  doctest Ivar.Utilities

  alias Ivar.Utilities
  
  test "get_mime_type/2 should return mime-type for given extension" do
    mime = Utilities.get_mime_type("jpg", :ext)
    
    assert mime == "image/jpeg"
  end
  
  test "get_mime_type/2 should return custom mime-type" do
    mime = Utilities.get_mime_type("custom/type", :ext)
    
    assert mime == "custom/type"
  end
  
  test "get_mime_type/2 should return file name mime type" do
    mime = Utilities.get_mime_type("test.jpg", :file)
    
    assert mime == "image/jpeg"
  end
end