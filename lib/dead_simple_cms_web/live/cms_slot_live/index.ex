defmodule DeadSimpleCmsWeb.CmsSlotLive.Index do
  @moduledoc """
  Section types (slots): the kinds of section the website knows how to lay
  out. Usually set up by a developer. A type in use can't be deleted.
  """
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header
      main_title="Section types"
      sub_title="Developer settings"
      description="Each section type is a layout the website's code knows how to show. Editors pick one for every section. Usually set up by your developer."
    >
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_slots/new")}>
          <.icon name="hero-plus" class="size-4" /> New section type
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_slots"
      rows={@streams.cms_slots}
      row_click={fn {_id, cms_slot} -> JS.navigate(DeadSimpleCms.path("/cms_slots/#{cms_slot.id}")) end}
      empty_title="No section types yet"
      empty_description="Add one for each kind of section your website can show."
    >
      <:col :let={{_id, cms_slot}} label="Name">{cms_slot.name}</:col>
      <:col :let={{_id, cms_slot}} label="Key"><code class="rounded bg-zinc-100 px-1.5 py-0.5 text-xs text-zinc-700">{cms_slot.key}</code></:col>
      <:col :let={{_id, cms_slot}} label="Description" extra_td_class="max-w-xs">
        <span class="line-clamp-2">{cms_slot.description}</span>
      </:col>
      <:col :let={{_id, cms_slot}} label="Used by">{usage_label(Map.get(@usage, cms_slot.id, 0))}</:col>

      <:action :let={{_id, cms_slot}}>
        <.link navigate={DeadSimpleCms.path("/cms_slots/#{cms_slot.id}/edit")}>Edit</.link>
      </:action>

      <:action :let={{_id, cms_slot}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_slot.id})} data-confirm={delete_confirm(cms_slot, Map.get(@usage, cms_slot.id, 0))}>
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
     |> assign(:page_title, "Section types")
     |> assign(:usage, Cms.slot_usage_counts())
     |> stream(:cms_slots, Cms.list_cms_slots() |> Enum.sort_by(&String.downcase(&1.name)))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_slot = Cms.get_cms_slot!(id)

    # Deleting a type in use would leave its sections with no type (and blank on the site).
    case Map.get(Cms.slot_usage_counts(), cms_slot.id, 0) do
      0 ->
        {:ok, _} = Cms.delete_cms_slot(cms_slot)
        {:noreply, socket |> put_flash(:info, "Section type \"#{cms_slot.name}\" deleted") |> stream_delete(:cms_slots, cms_slot)}

      count ->
        {:noreply, put_flash(socket, :error, "\"#{cms_slot.name}\" is used by #{usage_label(count)}. Change their type first.")}
    end
  end

  # In use, the click shows why it can't be deleted, so there's nothing to confirm.
  defp delete_confirm(cms_slot, 0), do: "Delete the section type \"#{cms_slot.name}\"? No sections use it. This can't be undone."
  defp delete_confirm(_cms_slot, _count), do: nil

  defp usage_label(1), do: "1 section"
  defp usage_label(count), do: "#{count} sections"
end
