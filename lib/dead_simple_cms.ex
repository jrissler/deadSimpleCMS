defmodule DeadSimpleCms do
  @moduledoc """
  Dead Simple CMS

  Library scope:
  - Content storage, validation, CRUD, and admin UI only
  - No caching
  - No auth/roles (host app wraps admin routes)
  - Parent app owns public rendering and theming
  """

  def repo! do
    case Application.get_env(:dead_simple_cms, :repo) do
      nil -> raise ArgumentError, "config :dead_simple_cms, repo: MyApp.Repo is required"
      repo -> repo
    end
  end

  def path(suffix) do
    prefix = Application.get_env(:dead_simple_cms, :admin_path, "") |> normalize()
    prefix <> suffix
  end

  def ensure_ex_aws_configured do
    s3 = Application.get_env(:dead_simple_cms, :s3)

    unless is_list(s3) do
      raise ArgumentError,
            "config :dead_simple_cms, :s3, [...] is required (must include :region, :access_key_id, :secret_access_key, :bucket)"
    end

    region = Keyword.get(s3, :region)
    access_key_id = Keyword.get(s3, :access_key_id)
    secret_access_key = Keyword.get(s3, :secret_access_key)
    bucket = Keyword.get(s3, :bucket)

    if is_nil(region) or is_nil(access_key_id) or is_nil(secret_access_key) or is_nil(bucket) do
      raise ArgumentError,
            "config :dead_simple_cms, :s3 must include :region, :access_key_id, :secret_access_key, :bucket"
    end

    Application.put_env(:ex_aws, :json_codec, Jason)
    Application.put_env(:ex_aws, :region, region)
    Application.put_env(:ex_aws, :access_key_id, access_key_id)
    Application.put_env(:ex_aws, :secret_access_key, secret_access_key)
    Application.put_env(:ex_aws, :bucket, bucket)

    :ok
  end

  defp normalize(""), do: ""
  defp normalize(path), do: "/" <> String.trim(path, "/")
end
