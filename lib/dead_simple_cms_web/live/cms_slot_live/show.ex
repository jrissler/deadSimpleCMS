defmodule DeadSimpleCmsWeb.CmsSlotLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Viewing CMS Slot" sub_title={@cms_slot.name} description="This slot defines a stable renderable position that content areas can target.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_slots")} class="inline-flex mr-1 items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
          <.icon name="hero-list-bullet" class="-ml-0.5 mr-1 h-5 w-5" /> View All
        </.link>

        <.link navigate={DeadSimpleCms.path("/cms_slots/#{@cms_slot.id}/edit?return_to=show")} class="inline-flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> Edit Slot
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0 bg-white">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-slot-details-heading">
            <.non_list_table object_name="cms_slot" headers={["Field", "Value"]}>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Key</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_slot.key}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Name</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_slot.name}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Description</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_slot.description}</td>
              </:row>
            </.non_list_table>
          </section>
        </div>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "CMS Slot Details")
     |> assign(:cms_slot, Cms.get_cms_slot!(id))}
  end
end
