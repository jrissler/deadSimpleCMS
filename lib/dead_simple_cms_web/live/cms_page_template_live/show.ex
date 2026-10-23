defmodule DeadSimpleCmsWeb.CmsPageTemplateLive.Show do
  @moduledoc "A template at a glance: its starter and shared sections, and the pages using it."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@cms_page_template.name} sub_title="Template" description={@cms_page_template.description || "A template for new pages."}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_page_templates")}>
          <.icon name="hero-arrow-left" class="size-4" /> All templates
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_page_templates/#{@cms_page_template.id}/edit")}>
          <.icon name="hero-pencil" class="size-4" /> Edit template
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <section class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 class="text-base font-semibold text-zinc-900">Sections</h2>
          <ol :if={@cms_page_template.cms_content_areas != []} id="template-sections" class="mt-4 divide-y divide-zinc-100">
            <li :for={{area, index} <- Enum.with_index(@cms_page_template.cms_content_areas)} class="flex items-center gap-4 py-3">
              <span class="w-5 shrink-0 text-sm font-bold tabular-nums text-zinc-400">{index + 1}</span>
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-semibold text-zinc-900">{area.title || area.name}</p>
                <p :if={area.cms_slot} class="text-xs text-zinc-500">{area.cms_slot.name}</p>
              </div>
              <.status_badge tone={if area.shared, do: :good, else: :muted}>{if area.shared, do: "Shared on every page", else: "Starter"}</.status_badge>
            </li>
          </ol>
          <p :if={@cms_page_template.cms_content_areas == []} class="mt-4 text-sm text-zinc-500">No sections yet. Edit the template to add some.</p>
        </section>

        <aside class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 class="text-base font-semibold text-zinc-900">Used by</h2>
          <ul :if={@pages != []} class="mt-4 space-y-2 text-sm">
            <li :for={page <- @pages}>
              <.link navigate={DeadSimpleCms.path("/cms_pages/#{page.id}/edit")} class="font-semibold text-indigo-600 hover:text-indigo-500">{page.title}</.link>
            </li>
          </ul>
          <p :if={@pages == []} class="mt-4 text-sm text-zinc-500">No pages use this template yet.</p>
          <p class="mt-6 text-xs text-zinc-500">Key: <code>{@cms_page_template.key}</code></p>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    template = Cms.get_cms_page_template!(id)
    pages = Enum.filter(Cms.list_cms_pages(), &(&1.cms_page_template_id == template.id))

    {:ok, socket |> assign(:page_title, template.name) |> assign(:cms_page_template, template) |> assign(:pages, pages)}
  end
end
