defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Viewing CMS Content Area" sub_title={@cms_content_area.name} description="This is a CMS content area record.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_content_areas")} class="inline-flex mr-1 items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
          <.icon name="hero-list-bullet" class="-ml-0.5 mr-1 h-5 w-5" /> View All
        </.link>

        <.link
          navigate={DeadSimpleCms.path("/cms_content_areas/#{@cms_content_area.id}/edit?return_to=show")}
          class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
        >
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> Edit Content Area
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0 bg-white">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-content-area-details-heading">
            <.non_list_table object_name="cms_content_area" headers={["Field", "Value"]}>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Position</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.position}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Name</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.name}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Page</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.cms_page_id}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Visible</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.visible}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Title</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.title}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Subtitle</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_content_area.subtitle}</td>
              </:row>

              <:row>
                <td class="data-table-td text-sm text-gray-500">Body (Markdown)</td>
                <td class="data-table-td text-sm text-gray-500 whitespace-pre-wrap">
                  {@cms_content_area.body_md}
                </td>
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
     |> assign(:page_title, "CMS Content Area Details")
     |> assign(:cms_content_area, Cms.get_cms_content_area!(id))}
  end
end
