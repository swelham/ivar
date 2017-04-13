defmodule IvarTest.Files do
  use ExUnit.Case, async: true
  doctest Ivar.Files

  alias Ivar.Files
  
  setup do
    file_data = File.read!("test/fixtures/elixir.png")

    {:ok, file_data: file_data}
  end
  
  test "put/2 should put single file into request map", %{file_data: file_data} do
    expect = file_component("test", file_data, "test.jpg", "image/jpeg")
    
    result = Files.put(%{}, {"test", file_data, "test.jpg", "jpg"})
    
    assert result == %{files: [expect]}
  end
  
  test "put/2 should put multiple files into request map", %{file_data: file_data} do
    expect = [
      file_component("test2", "some plain text", "test2.txt", "text/plain"),
      file_component("test", file_data, "test.jpg", "image/jpeg")
    ]
    
    result = Files.put(%{}, [
      {"test", file_data, "test.jpg", "jpg"},
      {"test2", "some plain text", "test2.txt", "text"}
    ])
    
    assert result == %{files: expect}
  end
  
  test "put/2 should put file into existing :url_encoded request body", %{file_data: file_data} do
    expect = file_component("test", file_data, "test.jpg", "image/jpeg")
    
    result = %{}
    |> Ivar.Body.put(%{test: 123}, :url_encoded)
    |> Files.put({"test", file_data, "test.jpg", "jpg"})
    
    assert result.files == [expect]
  end
  
  test "put/2 should return error tuple when request is not url_encoded or multipart" do
    result = %{}
    |> Ivar.Body.put(%{test: 123}, :json)
    |> Files.put({"test", "", "test.jpg", "jpg"})
    
    assert result == {:error, "Files can only be put into a :url_encoded or :multipart body"}
  end
  
  test "put/2 should put a file with custom mime type into request map", %{file_data: file_data} do
    expect = file_component("test", file_data, "test.jpg", "custom/type")
    
    result = Files.put(%{}, {"test", file_data, "test.jpg", "custom/type"})
    
    assert result == %{files: [expect]}
  end
  
  test "put/2 should use the file name to resolve the mime type" do
    expect = file_component("test", "", "test.jpg", "image/jpeg")
    
    result = Files.put(%{}, {"test", "", "test.jpg"})
    
    assert result == %{files: [expect]}
  end
  
  defp file_component(name, data, file_name, type) do
    {
      name,
      data,
      {"form-data", [{"name", name}, {"filename", file_name}]},
      [{"content-type", type}]
    }
  end
end