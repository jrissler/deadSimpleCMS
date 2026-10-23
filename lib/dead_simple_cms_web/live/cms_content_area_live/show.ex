defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Show do
  @moduledoc "A section at a glance: where it lives, its type, image, words and status."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={label(@area)} sub_title="Section" description={"On #{owner_label(@area)}. Sections are usually edited from their page or template."}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_content_areas")}>
          <.icon name="hero-arrow-left" class="size-4" /> All sections
        </.button>
        <.button :if={owner_path(@area)} navigate={owner_path(@area)}>
          <.icon name="hero-document-text" class="size-4" /> {if @area.cms_page_template_id, do: "Open template", else: "Open page"}
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_content_areas/#{@area.id}/edit?return_to=show")}>
          <.icon name="hero-pencil" class="size-4" /> Edit section
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <section aria-labelledby="section-content-heading" class="space-y-5 rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 id="section-content-heading" class="text-base font-semibold text-zinc-900">Content</h2>

          <div :if={@area.cms_image} id="section-image">
            <img src={@area.cms_image.url} alt={@area.cms_image.alt || ""} class="max-h-72 w-full rounded-lg object-cover ring-1 ring-zinc-200" />
            <p class="mt-2 text-xs text-zinc-500">
              <span class="font-semibold text-zinc-700">Image description:</span> {present(@area.cms_image.alt) || "Not set. Add one so screen readers and search engines know what the photo shows."}
            </p>
            <p :if={present(@area.cms_image.caption)} class="mt-1 text-xs text-zinc-500">
              <span class="font-semibold text-zinc-700">Caption:</span> {@area.cms_image.caption}
            </p>
          </div>
          <p :if={!@area.cms_image} class="text-sm text-zinc-500">No image.</p>

          <dl class="space-y-4 text-sm">
            <div>
              <dt class="text-zinc-500">Title</dt>
              <dd class="mt-1 text-zinc-900">{present(@area.title) || "Not set"}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Subtitle</dt>
              <dd class="mt-1 text-zinc-900">{present(@area.subtitle) || "Not set"}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Body</dt>
              <dd :if={present(@area.body_md)} id="section-body" class="mt-1 whitespace-pre-wrap rounded-lg bg-zinc-50 p-4 leading-6 text-zinc-900 ring-1 ring-zinc-200">{@area.body_md}</dd>
              <dd :if={!present(@area.body_md)} class="mt-1 text-zinc-900">Not set</dd>
            </div>
          </dl>
        </section>

        <aside class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 class="text-base font-semibold text-zinc-900">Details</h2>
          <dl class="mt-4 space-y-3 text-sm">
            <div>
              <dt class="text-zinc-500">Lives on</dt>
              <dd class="mt-1">
                <.link :if={owner_path(@area)} navigate={owner_path(@area)} class="font-semibold text-indigo-600 hover:text-indigo-500">{owner_label(@area)}</.link>
                <span :if={!owner_path(@area)} class="text-zinc-900">{owner_label(@area)}</span>
              </dd>
            </div>
            <div>
              <dt class="text-zinc-500">Section type</dt>
              <dd class="mt-1 text-zinc-900">{(@area.cms_slot && @area.cms_slot.name) || "None"}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Status</dt>
              <dd class="mt-1 flex flex-wrap gap-2">
                <.status_badge tone={if @area.visible, do: :good, else: :dark}>{if @area.visible, do: "Shown", else: "Hidden"}</.status_badge>
                <.status_badge :if={@area.shared}>Shared on every page</.status_badge>
              </dd>
            </div>
            <div>
              <dt class="text-zinc-500">Order</dt>
              <dd class="mt-1 text-zinc-900">{@area.position}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Section name</dt>
              <dd class="mt-1 text-zinc-900">{@area.name}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Last updated</dt>
              <dd class="mt-1 text-zinc-900">{friendly_date(@area.updated_at)}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    area = id |> Cms.get_cms_content_area!() |> DeadSimpleCms.repo!().preload([:cms_page, :cms_page_template, :cms_slot])

    {:ok, socket |> assign(:page_title, label(area)) |> assign(:area, area)}
  end

  defp label(area), do: present(area.title) || area.name

  defp owner_label(%{cms_page: %{title: title}}), do: title
  defp owner_label(%{cms_page_template: %{name: name}}), do: "Template: #{name}"
  defp owner_label(_area), do: "no page"

  defp owner_path(%{cms_page_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_pages/#{id}/edit")
  defp owner_path(%{cms_page_template_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_page_templates/#{id}/edit")
  defp owner_path(_area), do: nil

  defp present(value) when value in [nil, ""], do: nil
  defp present(value), do: value
end
