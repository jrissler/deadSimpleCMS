defmodule DeadSimpleCmsWeb.Router do
  @moduledoc """
  Host mounts this under its own admin scope + auth pipeline + admin layout.

  Example in host router:
    scope "/admin", MyAppWeb do
      pipe_through [:browser, :require_admin]

      DeadSimpleCmsWeb.Router.dead_simple_cms_admin_routes()
    end
  """

  use DeadSimpleCmsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DeadSimpleCmsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DeadSimpleCmsWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/cms_pages", CmsPageLive.Index, :index
    live "/cms_pages/new", CmsPageLive.Form, :new
    live "/cms_pages/:id", CmsPageLive.Show, :show
    live "/cms_pages/:id/edit", CmsPageLive.Form, :edit

    live "/cms_images", CmsImageLive.Index, :index
    live "/cms_images/new", CmsImageLive.Form, :new
    live "/cms_images/:id", CmsImageLive.Show, :show
    live "/cms_images/:id/edit", CmsImageLive.Form, :edit

    live "/cms_content_areas", CmsContentAreaLive.Index, :index
    live "/cms_content_areas/new", CmsContentAreaLive.Form, :new
    live "/cms_content_areas/:id", CmsContentAreaLive.Show, :show
    live "/cms_content_areas/:id/edit", CmsContentAreaLive.Form, :edit
  end

  defmacro dead_simple_cms_admin_routes do
    quote do
      live "/cms_pages", DeadSimpleCmsWeb.CmsPageLive.Index, :index
      live "/cms_pages/new", DeadSimpleCmsWeb.CmsPageLive.Form, :new
      live "/cms_pages/:id", DeadSimpleCmsWeb.CmsPageLive.Show, :show
      live "/cms_pages/:id/edit", DeadSimpleCmsWeb.CmsPageLive.Form, :edit

      live "/cms_images", DeadSimpleCmsWeb.CmsImageLive.Index, :index
      live "/cms_images/new", DeadSimpleCmsWeb.CmsImageLive.Form, :new
      live "/cms_images/:id", DeadSimpleCmsWeb.CmsImageLive.Show, :show
      live "/cms_images/:id/edit", DeadSimpleCmsWeb.CmsImageLive.Form, :edit

      live "/cms_content_areas", DeadSimpleCmsWeb.CmsContentAreaLive.Index, :index
      live "/cms_content_areas/new", DeadSimpleCmsWeb.CmsContentAreaLive.Form, :new
      live "/cms_content_areas/:id", DeadSimpleCmsWeb.CmsContentAreaLive.Show, :show
      live "/cms_content_areas/:id/edit", DeadSimpleCmsWeb.CmsContentAreaLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DeadSimpleCmsWeb do
  #   pipe_through :api
  # end
end
