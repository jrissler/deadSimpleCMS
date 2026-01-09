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

  def s3_config do
    Application.get_env(:dead_simple_cms, :s3, [])
  end
end
