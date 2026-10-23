defmodule DeadSimpleCmsWeb.CmsSlotLive.Show do
  @moduledoc "A section type at a glance: its key, the help editors see, and every section using it."
  use DeadSimpleCmsWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@cms_slot.name} sub_title="Section type" description="A layout the website's code knows how to show. Editors pick it in the Section type list.">
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_slots")}>
          <.icon name="hero-arrow-left" class="size-4" /> All section types
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_slots/#{@cms_slot.id}/edit?return_to=show")}>
          <.icon name="hero-pencil" class="size-4" /> Edit section type
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <section aria-labelledby="slot-usage-heading" class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 id="slot-usage-heading" class="text-base font-semibold text-zinc-900">Used by {usage_label(length(@areas))}</h2>
          <ul :if={@areas != []} id="slot-sections" class="mt-4 divide-y divide-zinc-100">
            <li :for={area <- @areas} id={"slot-section-#{area.id}"} class="flex flex-wrap items-center justify-between gap-3 py-3">
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-zinc-900">{present(area.title) || area.name}</p>
                <p class="text-xs text-zinc-500">{owner_label(area)}</p>
              </div>
              <div class="flex items-center gap-3 text-sm font-semibold">
                <.status_badge :if={!area.visible} tone={:dark}>Hidden</.status_badge>
                <.link :if={owner_path(area)} navigate={owner_path(area)} class="text-indigo-600 hover:text-indigo-500">
                  {if area.cms_page_template_id, do: "Open template", else: "Open page"}
                </.link>
              </div>
            </li>
          </ul>
          <p :if={@areas == []} class="mt-4 text-sm text-zinc-500">No sections use this type yet. It can be deleted safely.</p>
        </section>

        <aside class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 class="text-base font-semibold text-zinc-900">Details</h2>
          <dl class="mt-4 space-y-3 text-sm">
            <div>
              <dt class="text-zinc-500">Key</dt>
              <dd class="mt-1"><code class="rounded bg-zinc-100 px-1.5 py-0.5 text-xs text-zinc-700">{@cms_slot.key}</code></dd>
            </div>
            <div>
              <dt class="text-zinc-500">Help shown to editors</dt>
              <dd class="mt-1 whitespace-pre-line text-zinc-900">{present(@cms_slot.description) || "None"}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Last updated</dt>
              <dd class="mt-1 text-zinc-900">{friendly_date(@cms_slot.updated_at)}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cms_slot = Cms.get_cms_slot!(id)

    {:ok, socket |> assign(:page_title, cms_slot.name) |> assign(:cms_slot, cms_slot) |> assign(:areas, list_slot_areas(cms_slot))}
  end

  # The sections using this type, pages first, then templates.
  defp list_slot_areas(cms_slot) do
    from(a in CmsContentArea, where: a.cms_slot_id == ^cms_slot.id, preload: [:cms_page, :cms_page_template])
    |> DeadSimpleCms.repo!().all()
    |> Enum.sort_by(&{if(&1.cms_page_template_id, do: 1, else: 0), String.downcase(owner_label(&1)), &1.position || 0})
  end

  defp owner_label(%{cms_page: %{title: title}}), do: title
  defp owner_label(%{cms_page_template: %{name: name}}), do: "Template: #{name}"
  defp owner_label(_area), do: "No page"

  defp owner_path(%{cms_page_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_pages/#{id}/edit")
  defp owner_path(%{cms_page_template_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_page_templates/#{id}/edit")
  defp owner_path(_area), do: nil

  defp usage_label(1), do: "1 section"
  defp usage_label(count), do: "#{count} sections"

  defp present(value) when value in [nil, ""], do: nil
  defp present(value), do: value
end
