defmodule Ivar.Body do
  @moduledoc """
  `Ivar.Body` manages the body content used for a request
  """

  alias Ivar.Utilities
  
  @doc """
  Puts the given `content` for the `content_type` into the existing `request` map
  
  Args
  
  * `request` - the map used to store the credentials, usually created via `Ivar.new/2`
  * `content` - the content for the request body
  * `content_type` - an atom for the type of content to put in the request body
  
  Usage
  
      iex> Ivar.Body.put(%{}, %{name: "value"}, :url_encoded)
      %{body: {:url_encoded, {"content-type", "application/x-www-form-urlencoded"}, "name=value"}}
  """
  def put(request, content, content_type),
    do: put_body(request, content, content_type)
    
  defp put_body(request, content, :json) when not is_binary(content) do
    case Poison.encode(content) do
      {:ok, body} -> put_body(request, body, :json)
      error -> error
    end
  end
  defp put_body(request, content, :json),
    do: put_body(request, content, "json", :json)
  
  defp put_body(request, content, :url_encoded) when not is_binary(content) do
    body = URI.encode_query(content)
    put_body(request, body, :url_encoded)
  end
  defp put_body(request, content, :url_encoded),
    do: put_body(request, content, "application/x-www-form-urlencoded", :url_encoded)
  
  defp put_body(request, content, type, known_type \\ nil) when is_binary(content) do
    type = Utilities.get_mime_type(type)

    header = content_header(type)
    
    body = {known_type || type, header, content}
    
    request
    |> Map.put(:body, body)
  end
  
  defp content_header(type),
    do: {"content-type", type}
end