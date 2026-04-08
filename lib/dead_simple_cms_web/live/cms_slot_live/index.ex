defmodule DeadSimpleCmsWeb.CmsSlotLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Slots" sub_title="Admin" description="Slots define stable renderable templates for content areas.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_slots/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Slot
        </.link>
      </:action>
    </.content_header>

    <.admin_table id="cms_slots" rows={@streams.cms_slots} row_click={fn {_id, cms_slot} -> JS.navigate(DeadSimpleCms.path("/cms_slots/#{cms_slot.id}")) end}>
      <:col :let={{_id, cms_slot}} label="Key">{cms_slot.key}</:col>
      <:col :let={{_id, cms_slot}} label="Name">{cms_slot.name}</:col>
      <:col :let={{_id, cms_slot}} label="Description">{cms_slot.description}</:col>

      <:action :let={{_id, cms_slot}}>
        <.link navigate={DeadSimpleCms.path("/cms_slots/#{cms_slot.id}/edit")}>
          Edit
        </.link>
      </:action>

      <:action :let={{_id, cms_slot}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_slot.id})} data-confirm="Are you sure?">
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
     |> assign(:page_title, "Listing CMS slots")
     |> stream(:cms_slots, Cms.list_cms_slots())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_slot = Cms.get_cms_slot!(id)
    {:ok, _} = Cms.delete_cms_slot(cms_slot)
    {:noreply, stream_delete(socket, :cms_slots, cms_slot)}
  end
end
