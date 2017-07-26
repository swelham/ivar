defmodule Ivar.Testing.TestAdapter do
  @moduledoc """
  TestAdapter is a testing utility that is designed to make testing Ivar simplier by replacing
  http requests with a callback that can be used to assert expected values for the request.
  """

  @empty_response {:ok, %{body: "", headers: [], status_code: 200}}

  @doc """
  This function executes a given `Ivar` request and run the function specified by the `:handler` option
  if this has been specified.
  
  Args
  
    * `request` - the map containing the request options to send, usually created via `Ivar.new/2`
  """
  @spec execute(map) :: map
  def execute(request) do
    handler = request
    |> Map.get(:opts, [])
    |> Keyword.get(:handler)

    case handler do
      nil -> @empty_response
      handler ->
        request = build_request(request)

        case handler.(request) do
          {:error, reason} -> {:error, reason}
          {:ok, nil} -> @empty_response
          response -> {:ok, build_response(response)}
        end
    end
  end

  defp build_request(request) do
    query = request
    |> Map.get(:opts, [])
    |> Keyword.get(:params)
    |> encode_query

    uri = URI.parse(request.url)
    files = Map.get(request, :files, [])

    %{
      method: method_string(request.method),
      headers: Map.get(request, :headers),
      body: Map.get(request, :body),
      query: query,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      files_count: length(files)
    }
  end

  defp build_response({:ok, {status, body}}) do
    %{
      status_code: status,
      body: body,
      headers: []
    }
  end
  defp build_response({:ok, {status, content_type, body}}) do
    {:ok, {status, body}}
    |> build_response
    |> append_content_type(content_type)
  end
  defp build_response(response), do: response

  defp encode_query(nil), do: ""
  defp encode_query(params), do: URI.encode_query(params)

  defp content_type_string(:json), do: "application/json"
  defp content_type_string(:url_encoded), do: "application/x-www-form-urlencoded"
  defp content_type_string(type), do: type

  defp append_content_type(response, type) do
    ctype = content_type_string(type)

    headers = response
    |> Map.get(:headers)
    |> Kernel.++([{"content-type", ctype}])

    Map.put(response, :headers, headers)
  end

  defp method_string(:get),     do: "GET"
  defp method_string(:post),    do: "POST"
  defp method_string(:put),     do: "PUT"
  defp method_string(:patch),   do: "PATCH"
  defp method_string(:delete),  do: "DELETE"
end
