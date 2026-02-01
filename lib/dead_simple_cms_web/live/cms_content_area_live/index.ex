defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Content Areas" sub_title="Admin" description="CMS Content Areas belong to a page, and house a specific piece of content.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_content_areas/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Content Area
        </.link>
      </:action>
    </.content_header>

    <.admin_table id="cms_content_areas" rows={@streams.cms_content_areas} row_click={fn {_id, area} -> JS.navigate(DeadSimpleCms.path("/cms_content_areas/#{area.id}")) end}>
      <:col :let={{_id, area}} label="Position">{area.position}</:col>
      <:col :let={{_id, area}} label="Name">{area.name}</:col>
      <:col :let={{_id, area}} label="Page">{area.cms_page_id}</:col>
      <:col :let={{_id, area}} label="Visible">{area.visible}</:col>
      <:col :let={{_id, area}} label="Updated">{Calendar.strftime(area.updated_at, "%Y-%m-%d")}</:col>

      <:action :let={{_id, area}}>
        <.link navigate={DeadSimpleCms.path("/cms_content_areas/#{area.id}/edit")}>Edit</.link>
      </:action>

      <:action :let={{_id, area}}>
        <.link phx-click={JS.push("delete", value: %{id: area.id})} data-confirm="Are you sure?">
          Delete
        </.link>
      </:action>
    </.admin_table>
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
