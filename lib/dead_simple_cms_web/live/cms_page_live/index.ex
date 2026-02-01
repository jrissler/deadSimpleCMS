defmodule DeadSimpleCmsWeb.CmsPageLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Pages" sub_title="Admin" description="Pages represent top-level routes and own ordered content areas.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_pages/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Page
        </.link>
      </:action>
    </.content_header>

    <.admin_table id="cms_pages" rows={@streams.cms_pages} row_click={fn {_id, page} -> JS.navigate(DeadSimpleCms.path("/cms_pages/#{page.id}")) end}>
      <:col :let={{_id, page}} label="Slug">{page.slug}</:col>
      <:col :let={{_id, page}} label="Title">{page.title}</:col>
      <:col :let={{_id, page}} label="Published">{page.published}</:col>
      <:col :let={{_id, page}} label="Published At">
        {page.published_at && Calendar.strftime(page.published_at, "%Y-%m-%d")}
      </:col>

      <:action :let={{_id, page}}>
        <.link navigate={DeadSimpleCms.path("/cms_pages/#{page.id}/edit")}>
          Edit
        </.link>
      </:action>

      <:action :let={{_id, page}}>
        <.link phx-click={JS.push("delete", value: %{id: page.id})} data-confirm="Are you sure?">
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
     |> assign(:page_title, "Listing CMS pages")
     |> stream(:cms_pages, Cms.list_cms_pages())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    page = Cms.get_cms_page!(id)
    {:ok, _} = Cms.delete_cms_page(page)
    {:noreply, stream_delete(socket, :cms_pages, page)}
  end
end
