defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Index do
  @moduledoc """
  Every section on the site in one list, by the page or template it lives on.
  Editors normally edit sections inside the page editor; this is the
  power-user view.
  """
  use DeadSimpleCmsWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header
      main_title="Sections"
      sub_title="Website content"
      description="Every section on the site, by page and template. Sections are usually edited from their page or template: use Open page to work on one in context."
    >
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_content_areas/new")}>
          <.icon name="hero-plus" class="size-4" /> New section
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_content_areas"
      rows={@streams.cms_content_areas}
      row_click={fn {_id, area} -> JS.navigate(DeadSimpleCms.path("/cms_content_areas/#{area.id}/edit")) end}
      empty_title="No sections yet"
      empty_description="Sections are added from a page or template editor."
    >
      <:col :let={{_id, area}} label="Section">
        <span class="block">{label(area)}</span>
        <span :if={present(area.title)} class="block text-xs font-normal text-zinc-500">{area.name}</span>
      </:col>
      <:col :let={{_id, area}} label="Lives on">{owner_label(area)}</:col>
      <:col :let={{_id, area}} label="Type">{(area.cms_slot && area.cms_slot.name) || "None"}</:col>
      <:col :let={{_id, area}} label="Status">
        <.status_badge tone={if area.visible, do: :good, else: :dark}>{if area.visible, do: "Shown", else: "Hidden"}</.status_badge>
        <.status_badge :if={area.shared}>Shared</.status_badge>
      </:col>
      <:action :let={{_id, area}}>
        <.link :if={owner_path(area)} navigate={owner_path(area)}>{if area.cms_page_template_id, do: "Open template", else: "Open page"}</.link>
      </:action>
      <:action :let={{_id, area}}>
        <.link phx-click={JS.push("delete", value: %{id: area.id})} data-confirm={"Delete the section \"#{label(area)}\" from #{owner_label(area)}? This can't be undone."}>
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
     |> assign(:page_title, "Sections")
     |> stream(:cms_content_areas, list_areas())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    area = id |> Cms.get_cms_content_area!() |> DeadSimpleCms.repo!().preload([:cms_page, :cms_page_template])
    {:ok, _} = Cms.delete_cms_content_area(area)

    {:noreply, socket |> put_flash(:info, "Section \"#{label(area)}\" deleted") |> stream_delete(:cms_content_areas, area)}
  end

  # Pages first, then templates, each by name, then by the sections' order.
  defp list_areas do
    from(a in CmsContentArea, preload: [:cms_page, :cms_page_template, :cms_slot])
    |> DeadSimpleCms.repo!().all()
    |> Enum.sort_by(&{if(&1.cms_page_template_id, do: 1, else: 0), String.downcase(owner_label(&1)), &1.position || 0})
  end

  defp label(area), do: present(area.title) || area.name

  defp owner_label(%{cms_page: %{title: title}}), do: title
  defp owner_label(%{cms_page_template: %{name: name}}), do: "Template: #{name}"
  defp owner_label(_area), do: "No page"

  defp owner_path(%{cms_page_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_pages/#{id}/edit")
  defp owner_path(%{cms_page_template_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_page_templates/#{id}/edit")
  defp owner_path(_area), do: nil

  defp present(value) when value in [nil, ""], do: nil
  defp present(value), do: value
end
