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

    live "/cms_slots", CmsSlotLive.Index, :index
    live "/cms_slots/new", CmsSlotLive.Form, :new
    live "/cms_slots/:id", CmsSlotLive.Show, :show
    live "/cms_slots/:id/edit", CmsSlotLive.Form, :edit

    live "/cms_images", CmsImageLive.Index, :index
    live "/cms_images/new", CmsImageLive.Form, :new
    live "/cms_images/:id", CmsImageLive.Show, :show
    live "/cms_images/:id/edit", CmsImageLive.Form, :edit

    live "/cms_content_areas", CmsContentAreaLive.Index, :index
    live "/cms_content_areas/new", CmsContentAreaLive.Form, :new
    live "/cms_content_areas/:id", CmsContentAreaLive.Show, :show
    live "/cms_content_areas/:id/edit", CmsContentAreaLive.Form, :edit

    live "/cms_bios", CmsBioLive.Index, :index
    live "/cms_bios/new", CmsBioLive.Form, :new
    live "/cms_bios/:id", CmsBioLive.Show, :show
    live "/cms_bios/:id/edit", CmsBioLive.Form, :edit

    live "/cms_testimonials", CmsTestimonialLive.Index, :index
    live "/cms_testimonials/new", CmsTestimonialLive.Form, :new
    live "/cms_testimonials/:id", CmsTestimonialLive.Show, :show
    live "/cms_testimonials/:id/edit", CmsTestimonialLive.Form, :edit
  end

  defmacro dead_simple_cms_admin_routes do
    quote do
      live "/cms_pages", DeadSimpleCmsWeb.CmsPageLive.Index, :index
      live "/cms_pages/new", DeadSimpleCmsWeb.CmsPageLive.Form, :new
      live "/cms_pages/:id", DeadSimpleCmsWeb.CmsPageLive.Show, :show
      live "/cms_pages/:id/edit", DeadSimpleCmsWeb.CmsPageLive.Form, :edit

      live "/cms_slots", DeadSimpleCmsWeb.CmsSlotLive.Index, :index
      live "/cms_slots/new", DeadSimpleCmsWeb.CmsSlotLive.Form, :new
      live "/cms_slots/:id", DeadSimpleCmsWeb.CmsSlotLive.Show, :show
      live "/cms_slots/:id/edit", DeadSimpleCmsWeb.CmsSlotLive.Form, :edit

      live "/cms_images", DeadSimpleCmsWeb.CmsImageLive.Index, :index
      live "/cms_images/new", DeadSimpleCmsWeb.CmsImageLive.Form, :new
      live "/cms_images/:id", DeadSimpleCmsWeb.CmsImageLive.Show, :show
      live "/cms_images/:id/edit", DeadSimpleCmsWeb.CmsImageLive.Form, :edit

      live "/cms_content_areas", DeadSimpleCmsWeb.CmsContentAreaLive.Index, :index
      live "/cms_content_areas/new", DeadSimpleCmsWeb.CmsContentAreaLive.Form, :new
      live "/cms_content_areas/:id", DeadSimpleCmsWeb.CmsContentAreaLive.Show, :show
      live "/cms_content_areas/:id/edit", DeadSimpleCmsWeb.CmsContentAreaLive.Form, :edit

      live "/cms_bios", DeadSimpleCmsWeb.CmsBioLive.Index, :index
      live "/cms_bios/new", DeadSimpleCmsWeb.CmsBioLive.Form, :new
      live "/cms_bios/:id", DeadSimpleCmsWeb.CmsBioLive.Show, :show
      live "/cms_bios/:id/edit", DeadSimpleCmsWeb.CmsBioLive.Form, :edit

      live "/cms_testimonials", DeadSimpleCmsWeb.CmsTestimonialLive.Index, :index
      live "/cms_testimonials/new", DeadSimpleCmsWeb.CmsTestimonialLive.Form, :new
      live "/cms_testimonials/:id", DeadSimpleCmsWeb.CmsTestimonialLive.Show, :show
      live "/cms_testimonials/:id/edit", DeadSimpleCmsWeb.CmsTestimonialLive.Form, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DeadSimpleCmsWeb do
  #   pipe_through :api
  # end
end
