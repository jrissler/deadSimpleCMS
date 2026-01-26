defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Cms content areas
        <:actions>
          <.button variant="primary" navigate={DeadSimpleCms.path("/cms_content_areas/new")}>
            <.icon name="hero-plus" /> New Cms content area
          </.button>
        </:actions>
      </.header>

      <.table
        id="cms_content_areas"
        rows={@streams.cms_content_areas}
        row_click={fn {_id, cms_content_area} -> JS.navigate(DeadSimpleCms.path("/cms_content_areas/#{cms_content_area.id}")) end}
      >
        <:col :let={{_id, cms_content_area}} label="Position">{cms_content_area.position}</:col>
        <:col :let={{_id, cms_content_area}} label="Name">{cms_content_area.name}</:col>
        <:col :let={{_id, cms_content_area}} label="Visible">{cms_content_area.visible}</:col>
        <:col :let={{_id, cms_content_area}} label="Title">{cms_content_area.title}</:col>
        <:col :let={{_id, cms_content_area}} label="Subtitle">{cms_content_area.subtitle}</:col>
        <:col :let={{_id, cms_content_area}} label="Body md">{cms_content_area.body_md}</:col>

        <:action :let={{_id, cms_content_area}}>
          <div class="sr-only">
            <.link navigate={DeadSimpleCms.path("/cms_content_areas/#{cms_content_area.id}")}>Show</.link>
          </div>
          <.link navigate={DeadSimpleCms.path("/cms_content_areas/#{cms_content_area.id}/edit")}>Edit</.link>
        </:action>

        <:action :let={{id, cms_content_area}}>
          <.link
            phx-click={JS.push("delete", value: %{id: cms_content_area.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Cms content areas")
     |> stream(:cms_content_areas, Cms.list_cms_content_areas())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_content_area = Cms.get_cms_content_area!(id)
    {:ok, _} = Cms.delete_cms_content_area(cms_content_area)

    {:noreply, stream_delete(socket, :cms_content_areas, cms_content_area)}
  end
end
