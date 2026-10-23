defmodule DeadSimpleCmsWeb.CmsPageTemplateLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Templates" sub_title="Website content" description="Templates give new pages their starting sections, and can add shared sections to every page that uses them.">
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_page_templates/new")}>
          <.icon name="hero-plus" class="size-4" /> New template
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_page_templates"
      rows={@streams.cms_page_templates}
      row_click={fn {_id, template} -> JS.navigate(DeadSimpleCms.path("/cms_page_templates/#{template.id}/edit")) end}
      empty_title="No templates yet"
      empty_description="Templates are optional. Create one to give new pages a ready-made set of sections."
    >
      <:col :let={{_id, template}} label="Template">
        <span class="block">{template.name}</span>
        <span :if={template.description} class="block max-w-md text-xs font-normal text-zinc-500">{template.description}</span>
      </:col>
      <:col :let={{_id, template}} label="Sections">{Map.get(@area_counts, template.id, 0)}</:col>
      <:col :let={{_id, template}} label="Used by">{pages_label(Map.get(@page_counts, template.id, 0))}</:col>

      <:action :let={{_id, template}}>
        <.link navigate={DeadSimpleCms.path("/cms_page_templates/#{template.id}/edit")}>Edit</.link>
      </:action>
      <:action :let={{_id, template}}>
        <.link
          phx-click={JS.push("delete", value: %{id: template.id})}
          data-confirm={"Delete the template \"#{template.name}\"? Pages using it keep their own sections but lose its shared sections. This can't be undone."}
        >
          Delete
        </.link>
      </:action>
    </.admin_table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    page_counts = Cms.list_cms_pages() |> Enum.frequencies_by(& &1.cms_page_template_id)

    {:ok,
     socket
     |> assign(:page_title, "Templates")
     |> assign(:area_counts, Cms.content_area_counts())
     |> assign(:page_counts, page_counts)
     |> stream(:cms_page_templates, Enum.sort_by(Cms.list_cms_page_templates(), &String.downcase(&1.name)))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    template = Cms.get_cms_page_template!(id)
    {:ok, _} = Cms.delete_cms_page_template(template)
    {:noreply, socket |> put_flash(:info, "Template \"#{template.name}\" deleted") |> stream_delete(:cms_page_templates, template)}
  end

  defp pages_label(0), do: "No pages"
  defp pages_label(1), do: "1 page"
  defp pages_label(count), do: "#{count} pages"
end
