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
  end

  defmacro dead_simple_cms_admin_routes do
    pages_index = DeadSimpleCmsWeb.PagesLive.Index
    pages_show = DeadSimpleCmsWeb.PagesLive.Show
    images_index = DeadSimpleCmsWeb.ImagesLive.Index

    quote bind_quoted: [
            pages_index: pages_index,
            pages_show: pages_show,
            images_index: images_index
          ] do
      live "/pages", pages_index, :index
      live "/pages/:id", pages_show, :show
      live "/images", images_index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DeadSimpleCmsWeb do
  #   pipe_through :api
  # end
end
