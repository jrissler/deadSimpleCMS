defmodule DeadSimpleCmsWeb.CmsImageLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Cms images
      <:actions>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_images/new")}>
          <.icon name="hero-plus" /> New Cms image
        </.button>
      </:actions>
    </.header>

    <.table
      id="cms_images"
      rows={@streams.cms_images}
      row_click={fn {_id, cms_image} -> JS.navigate(DeadSimpleCms.path("/cms_images/#{cms_image.id}")) end}
    >
      <:col :let={{_id, cms_image}} label="Alt">{cms_image.alt}</:col>
      <:col :let={{_id, cms_image}} label="Url">{cms_image.url}</:col>

      <:action :let={{_id, cms_image}}>
        <div class="sr-only">
          <.link navigate={DeadSimpleCms.path("/cms_images/#{cms_image.id}")}>Show</.link>
        </div>
        <.link navigate={DeadSimpleCms.path("/cms_images/#{cms_image.id}/edit")}>Edit</.link>
      </:action>

      <:action :let={{id, cms_image}}>
        <.link
          phx-click={JS.push("delete", value: %{id: cms_image.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Cms images")
     |> stream(:cms_images, Cms.list_cms_images())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_image = Cms.get_cms_image!(id)
    {:ok, _} = Cms.delete_cms_image(cms_image)
    {:noreply, stream_delete(socket, :cms_images, cms_image)}
  end
end
