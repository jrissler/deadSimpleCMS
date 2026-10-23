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

  @doc """
  The host app's full-page preview URL for a CMS page, or `nil`.

  Built from `config :dead_simple_cms, page_preview_url: "/preview/:slug"`,
  replacing `:slug` and `:id`. The host owns the preview route and its
  rendering (drafts included, behind its own auth). Returns `nil` when the
  setting is absent or the page has no slug yet, and the admin then hides
  its Preview Page button.

  ## Examples

      iex> page_preview_url(%CmsPage{slug: "about"})
      "/preview/about"

  """
  def page_preview_url(%{slug: slug} = page) when is_binary(slug) and slug != "" do
    case Application.get_env(:dead_simple_cms, :page_preview_url) do
      template when is_binary(template) -> template |> String.replace(":slug", slug) |> String.replace(":id", to_string(page.id))
      _ -> nil
    end
  end

  def page_preview_url(_page), do: nil

  @doc """
  Ensures the S3 settings needed for image uploads are present.

  `config :dead_simple_cms, :s3` must include `:bucket`. `:region`,
  `:access_key_id`, and `:secret_access_key` are optional: when given they are
  written to the `:ex_aws` config, and when omitted the host app's existing
  `:ex_aws` config is used as-is.
  """
  def ensure_ex_aws_configured do
    s3 = Application.get_env(:dead_simple_cms, :s3)

    unless is_list(s3) and is_binary(Keyword.get(s3, :bucket)) do
      raise ArgumentError, "config :dead_simple_cms, :s3, bucket: \"...\" is required"
    end

    for key <- [:region, :access_key_id, :secret_access_key], value = Keyword.get(s3, key), not is_nil(value) do
      Application.put_env(:ex_aws, key, value)
    end

    unless Application.get_env(:ex_aws, :json_codec), do: Application.put_env(:ex_aws, :json_codec, Jason)

    :ok
  end

  defp normalize(""), do: ""
  defp normalize(path), do: "/" <> String.trim(path, "/")
end
