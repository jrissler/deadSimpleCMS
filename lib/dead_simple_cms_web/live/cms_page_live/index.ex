defmodule DeadSimpleCmsWeb.CmsPageLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Pages" sub_title="Website content" description="Each page is a set of sections in order. Click a page to edit it.">
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_pages/new")}>
          <.icon name="hero-plus" class="size-4" /> New page
        </.button>
      </:action>
    </.content_header>

    <.link
      id="ai-coming-soon"
      navigate={DeadSimpleCms.path("/about") <> "#coming-soon"}
      class="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-2xl bg-gradient-to-r from-indigo-600 to-slate-900 px-5 py-3 text-sm text-white shadow-sm hover:from-indigo-500"
    >
      <.icon name="hero-sparkles" class="size-5 text-indigo-200" />
      <span class="font-semibold">Coming soon: build pages by talking to Claude or ChatGPT.</span>
      <span class="text-indigo-100">Describe what you want and get a draft to review.</span>
      <span class="ml-auto font-semibold">Learn more &rarr;</span>
    </.link>

    <.admin_table
      id="cms_pages"
      rows={@streams.cms_pages}
      row_click={fn {_id, page} -> JS.navigate(DeadSimpleCms.path("/cms_pages/#{page.id}/edit")) end}
      empty_title="No pages yet"
      empty_description="Create your first page to start adding sections."
    >
      <:col :let={{_id, page}} label="Page">
        <span class="block">{page.title}</span>
        <span class="block text-xs font-normal text-zinc-500">/{page.slug}</span>
      </:col>
      <:col :let={{_id, page}} label="Status">
        <.status_badge tone={if page.published, do: :good, else: :muted}>{if page.published, do: "Live", else: "Draft"}</.status_badge>
        <.status_badge :if={page.noindex} tone={:warning}>Hidden from search</.status_badge>
      </:col>
      <:col :let={{_id, page}} label="Template">{(page.cms_page_template && page.cms_page_template.name) || "None"}</:col>
      <:col :let={{_id, page}} label="Sections">{Map.get(@area_counts, page.id, 0)}</:col>
      <:col :let={{_id, page}} label="Updated">{friendly_date(page.updated_at)}</:col>

      <:action :let={{_id, page}}>
        <.link navigate={DeadSimpleCms.path("/cms_pages/#{page.id}/edit")}>Edit</.link>
      </:action>
      <:action :let={{_id, page}}>
        <.link :if={DeadSimpleCms.page_preview_url(page)} href={DeadSimpleCms.page_preview_url(page)} target="_blank" rel="noopener">Preview</.link>
      </:action>
      <:action :let={{_id, page}}>
        <.link
          phx-click={JS.push("delete", value: %{id: page.id})}
          data-confirm={"Delete the page \"#{page.title}\" and its #{Map.get(@area_counts, page.id, 0)} sections? This can't be undone."}
        >
          Delete
        </.link>
      </:action>
    </.admin_table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    pages = Cms.list_cms_pages() |> DeadSimpleCms.repo!().preload(:cms_page_template) |> Enum.sort_by(&String.downcase(&1.title))

    {:ok,
     socket
     |> assign(:page_title, "Pages")
     |> assign(:area_counts, Cms.content_area_counts())
     |> stream(:cms_pages, pages)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    page = Cms.get_cms_page!(id)
    {:ok, _} = Cms.delete_cms_page(page)
    {:noreply, socket |> put_flash(:info, "Page \"#{page.title}\" deleted") |> stream_delete(:cms_pages, page)}
  end
end
