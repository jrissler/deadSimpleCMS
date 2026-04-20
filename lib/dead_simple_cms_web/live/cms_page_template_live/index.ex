defmodule DeadSimpleCmsWeb.CmsPageTemplateLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Page Templates" sub_title="Admin" description="Page templates define the overall content structure pattern for CMS pages.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_page_templates/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Page Template
        </.link>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_page_templates"
      rows={@streams.cms_page_templates}
      row_click={fn {_id, cms_page_template} -> JS.navigate(DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}")) end}
    >
      <:col :let={{_id, cms_page_template}} label="Key">{cms_page_template.key}</:col>
      <:col :let={{_id, cms_page_template}} label="Name">{cms_page_template.name}</:col>
      <:col :let={{_id, cms_page_template}} label="Description">{cms_page_template.description}</:col>

      <:action :let={{_id, cms_page_template}}>
        <.link navigate={DeadSimpleCms.path("/cms_page_templates/#{cms_page_template.id}/edit")}>
          Edit
        </.link>
      </:action>

      <:action :let={{_id, cms_page_template}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_page_template.id})} data-confirm="Are you sure?">
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
     |> assign(:page_title, "Listing CMS page templates")
     |> stream(:cms_page_templates, list_cms_page_templates())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_page_template = Cms.get_cms_page_template!(id)
    {:ok, _} = Cms.delete_cms_page_template(cms_page_template)

    {:noreply, stream_delete(socket, :cms_page_templates, cms_page_template)}
  end

  defp list_cms_page_templates do
    Cms.list_cms_page_templates()
  end
end
