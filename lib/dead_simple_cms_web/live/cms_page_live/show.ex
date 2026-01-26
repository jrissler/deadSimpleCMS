defmodule DeadSimpleCmsWeb.CmsPageLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Cms page {@cms_page.id}
        <:subtitle>This is a cms_page record from your database.</:subtitle>
        <:actions>
          <.button navigate={DeadSimpleCms.path("/cms_pages")}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={DeadSimpleCms.path("/cms_pages/#{@cms_page.id}/edit?return_to=show")}>
            <.icon name="hero-pencil-square" /> Edit cms_page
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Slug">{@cms_page.slug}</:item>
        <:item title="Title">{@cms_page.title}</:item>
        <:item title="Published">{@cms_page.published}</:item>
        <:item title="Published at">{@cms_page.published_at}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Cms page")
     |> assign(:cms_page, Cms.get_cms_page!(id))}
  end
end
