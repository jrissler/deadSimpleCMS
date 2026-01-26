defmodule DeadSimpleCmsWeb.CmsPageLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Cms pages
        <:actions>
          <.button variant="primary" navigate={DeadSimpleCms.path("/cms_pages/new")}>
            <.icon name="hero-plus" /> New Cms page
          </.button>
        </:actions>
      </.header>

      <.table
        id="cms_pages"
        rows={@streams.cms_pages}
        row_click={fn {_id, cms_page} -> JS.navigate(DeadSimpleCms.path("/cms_pages/#{cms_page.id}")) end}
      >
        <:col :let={{_id, cms_page}} label="Slug">{cms_page.slug}</:col>
        <:col :let={{_id, cms_page}} label="Title">{cms_page.title}</:col>
        <:col :let={{_id, cms_page}} label="Published">{cms_page.published}</:col>
        <:col :let={{_id, cms_page}} label="Published at">{cms_page.published_at}</:col>

        <:action :let={{_id, cms_page}}>
          <div class="sr-only">
            <.link navigate={DeadSimpleCms.path("/cms_pages/#{cms_page.id}")}>Show</.link>
          </div>
          <.link navigate={DeadSimpleCms.path("/cms_pages/#{cms_page.id}/edit")}>Edit</.link>
        </:action>

        <:action :let={{id, cms_page}}>
          <.link
            phx-click={JS.push("delete", value: %{id: cms_page.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Cms pages")
     |> stream(:cms_pages, Cms.list_cms_pages())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_page = Cms.get_cms_page!(id)
    {:ok, _} = Cms.delete_cms_page(cms_page)
    {:noreply, stream_delete(socket, :cms_pages, cms_page)}
  end
end
