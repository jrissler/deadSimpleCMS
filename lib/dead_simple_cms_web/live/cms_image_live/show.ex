defmodule DeadSimpleCmsWeb.CmsImageLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Cms image {@cms_image.id}
        <:subtitle>This is a cms_image record from your database.</:subtitle>
        <:actions>
          <.button navigate={DeadSimpleCms.path("/cms_images")}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={DeadSimpleCms.path("/cms_images/#{@cms_image.id}/edit?return_to=show")}>
            <.icon name="hero-pencil-square" /> Edit cms_image
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Alt">{@cms_image.alt}</:item>
        <:item title="Url">{@cms_image.url}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Cms image")
     |> assign(:cms_image, Cms.get_cms_image!(id))}
  end
end
