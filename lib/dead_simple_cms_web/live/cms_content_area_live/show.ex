defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Show do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
      <.header>
        Cms content area {@cms_content_area.id}
        <:subtitle>This is a cms_content_area record from your database.</:subtitle>
        <:actions>
          <.button navigate={DeadSimpleCms.path("/cms_content_areas")}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={DeadSimpleCms.path("/cms_content_areas/#{@cms_content_area.id}/edit?return_to=show")}>
            <.icon name="hero-pencil-square" /> Edit cms_content_area
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Position">{@cms_content_area.position}</:item>
        <:item title="Name">{@cms_content_area.name}</:item>
        <:item title="Visible">{@cms_content_area.visible}</:item>
        <:item title="Title">{@cms_content_area.title}</:item>
        <:item title="Subtitle">{@cms_content_area.subtitle}</:item>
        <:item title="Body md">{@cms_content_area.body_md}</:item>
      </.list>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, socket |> assign(:page_title, "Show Cms content area") |> assign(:cms_content_area, Cms.get_cms_content_area!(id))}
  end
end
