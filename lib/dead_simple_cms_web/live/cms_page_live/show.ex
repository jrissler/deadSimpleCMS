defmodule DeadSimpleCmsWeb.CmsPageLive.Show do
  @moduledoc "A page at a glance: its status, search details and sections, with links to edit and preview."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@cms_page.title} sub_title="Page" description={"/#{@cms_page.slug}"}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_pages")}>
          <.icon name="hero-arrow-left" class="size-4" /> All pages
        </.button>
        <.preview_page_link cms_page={@cms_page} />
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_pages/#{@cms_page.id}/edit")}>
          <.icon name="hero-pencil" class="size-4" /> Edit page
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <section aria-labelledby="page-sections-heading" class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 id="page-sections-heading" class="text-base font-semibold text-zinc-900">Sections</h2>
          <ol :if={@cms_page.cms_content_areas != []} id="page-sections" class="mt-4 divide-y divide-zinc-100">
            <li :for={{area, index} <- Enum.with_index(@cms_page.cms_content_areas)} class="flex items-center gap-4 py-3">
              <span class="w-5 shrink-0 text-sm font-bold tabular-nums text-zinc-400">{index + 1}</span>
              <img :if={area.cms_image} src={Cms.image_url(area.cms_image)} alt="" class="h-10 w-14 shrink-0 rounded object-cover ring-1 ring-zinc-200" />
              <div :if={!area.cms_image} class="h-10 w-14 shrink-0 rounded bg-zinc-100 ring-1 ring-zinc-200"></div>
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-semibold text-zinc-900">{area.title || area.name}</p>
                <p :if={area.cms_slot} class="text-xs text-zinc-500">{area.cms_slot.name}</p>
              </div>
              <.status_badge :if={!area.visible} tone={:dark}>Hidden</.status_badge>
            </li>
          </ol>
          <p :if={@cms_page.cms_content_areas == []} class="mt-4 text-sm text-zinc-500">No sections yet. Edit the page to add some.</p>
        </section>

        <aside class="space-y-6">
          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">Status</h2>
            <dl class="mt-4 space-y-3 text-sm">
              <div>
                <dt class="text-zinc-500">Visibility</dt>
                <dd class="mt-1">
                  <.status_badge tone={if @cms_page.published, do: :good, else: :muted}>{if @cms_page.published, do: "Live", else: "Draft"}</.status_badge>
                </dd>
              </div>
              <div :if={@cms_page.published_at}>
                <dt class="text-zinc-500">Publish date</dt>
                <dd class="mt-1 text-zinc-900">{friendly_date(@cms_page.published_at)}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">Template</dt>
                <dd class="mt-1 text-zinc-900">{(@cms_page.cms_page_template && @cms_page.cms_page_template.name) || "None"}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">Last updated</dt>
                <dd class="mt-1 text-zinc-900">{friendly_date(@cms_page.updated_at)}</dd>
              </div>
            </dl>
          </div>

          <div class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
            <h2 class="text-base font-semibold text-zinc-900">Search and sharing</h2>
            <dl class="mt-4 space-y-3 text-sm">
              <div>
                <dt class="text-zinc-500">Search title</dt>
                <dd class="mt-1 text-zinc-900">{@cms_page.meta_title || @cms_page.title}</dd>
              </div>
              <div>
                <dt class="text-zinc-500">Search description</dt>
                <dd class="mt-1 text-zinc-900">{@cms_page.meta_description || "Not set"}</dd>
              </div>
              <div :if={@cms_page.og_image}>
                <dt class="text-zinc-500">Share image</dt>
                <dd class="mt-1"><img src={Cms.image_url(@cms_page.og_image)} alt={@cms_page.og_image.alt || ""} class="h-20 w-32 rounded-lg object-cover ring-1 ring-zinc-200" /></dd>
              </div>
              <div :if={@cms_page.noindex}>
                <dd>
                  <.status_badge tone={:warning}>Hidden from search engines</.status_badge>
                </dd>
              </div>
            </dl>
          </div>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cms_page = id |> Cms.get_cms_page!() |> DeadSimpleCms.repo!().preload(:cms_page_template)

    {:ok, socket |> assign(:page_title, cms_page.title) |> assign(:cms_page, cms_page)}
  end
end
