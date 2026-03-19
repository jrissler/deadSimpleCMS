defmodule DeadSimpleCmsWeb.CmsBioLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Viewing CMS Bio" sub_title={@cms_bio.name} description="This bio represents standalone profile content with its own path.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_bios")} class="inline-flex mr-1 items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-3 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
          <.icon name="hero-list-bullet" class="-ml-0.5 mr-1 h-5 w-5" /> View All
        </.link>

        <.link navigate={DeadSimpleCms.path("/cms_bios/#{@cms_bio.id}/edit?return_to=show")} class="inline-flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> Edit Bio
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0 bg-white">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-bio-details-heading">
            <.non_list_table object_name="cms_bio" headers={["Field", "Value"]}>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Name</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.name}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Job Title</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.job_title}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Tag Line</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.tag_line}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Description</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.description}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Phone Number</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.phone_number}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Email</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.email}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Facebook</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.facebook}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Instagram</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.instagram}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Tik Tok</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.tik_tok}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Linked In</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.linked_in}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Slug</td>
                <td class="data-table-td text-sm text-gray-500">{@cms_bio.slug}</td>
              </:row>
              <:row>
                <td class="data-table-td text-sm text-gray-500">Visible</td>
                <td class="data-table-td text-sm text-gray-500">
                  {(@cms_bio.visible && "Yes") || "No"}
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
     |> assign(:page_title, "CMS Bio Details")
     |> assign(:cms_bio, SpecialContent.get_cms_bio!(id))}
  end
end
