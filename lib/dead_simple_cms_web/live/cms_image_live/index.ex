defmodule DeadSimpleCmsWeb.CmsImageLive.Index do
  @moduledoc "The image library: a thumbnail of every image, what needs attention, and where each one is used."
  use DeadSimpleCmsWeb, :live_view

  import Ecto.Query, warn: false
  import DeadSimpleCmsWeb.CmsImageLive.Show, only: [usage_items: 1, usage_summary: 1, delete_confirmation: 2, placeholder?: 1, present?: 1, delete_image: 1]

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.{CmsContentArea, CmsPage}
  alias DeadSimpleCms.SpecialContent.CmsBio

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Images" sub_title="Website content" description="Photos you can reuse in sections, bios and page share images. Click an image to see it large and where it's used.">
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_images/new")}>
          <.icon name="hero-plus" class="size-4" /> Add image
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_images"
      rows={@streams.cms_images}
      row_click={fn {_id, image} -> JS.navigate(DeadSimpleCms.path("/cms_images/#{image.id}")) end}
      empty_title="No images yet"
      empty_description="Add your first image to use it in sections, bios and share images."
    >
      <:col :let={{_id, image}} label="Image">
        <img src={Cms.image_url(image)} alt="" loading="lazy" class="h-14 w-20 rounded-md object-cover ring-1 ring-zinc-200" />
      </:col>
      <:col :let={{_id, image}} label="File and description">
        <span class="block max-w-sm truncate">{image.filename}</span>
        <span :if={present?(image.alt)} class="block max-w-sm truncate text-xs font-normal text-zinc-500">{image.alt}</span>
        <span class="mt-1 flex flex-wrap gap-1">
          <.status_badge :if={!present?(image.alt)} tone={:warning}>Needs a description</.status_badge>
          <.status_badge :if={placeholder?(image)} tone={:warning}>Placeholder</.status_badge>
        </span>
      </:col>
      <:col :let={{_id, image}} label="Used">
        <span class={if usage_for(@usage, image) == [], do: "font-normal text-zinc-500", else: "font-normal"}>
          {usage_summary(usage_for(@usage, image)) |> String.trim_trailing(".")}
        </span>
      </:col>

      <:action :let={{_id, image}}>
        <.link phx-click={JS.push("delete", value: %{id: image.id})} data-confirm={delete_confirmation(image, usage_for(@usage, image))}>
          Delete
        </.link>
      </:action>
    </.admin_table>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    images = Enum.sort_by(Cms.list_cms_images(), & &1.inserted_at, {:desc, DateTime})

    {:ok,
     socket
     |> assign(:page_title, "Images")
     |> assign(:usage, usage_by_image())
     |> stream(:cms_images, images)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    image = Cms.get_cms_image!(id)

    case delete_image(image) do
      {:ok, message} -> {:noreply, socket |> put_flash(:info, message) |> stream_delete(:cms_images, image)}
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp usage_for(usage, image), do: Map.get(usage, image.id, [])

  # Where every image is used, as `%{image_id => usage_items}`, in three queries.
  defp usage_by_image do
    repo = DeadSimpleCms.repo!()
    areas = repo.all(from(a in CmsContentArea, where: not is_nil(a.cms_image_id), order_by: a.name, preload: [:cms_page, :cms_page_template]))
    bios = repo.all(from(b in CmsBio, where: not is_nil(b.cms_image_id), order_by: b.name))
    pages = repo.all(from(p in CmsPage, where: not is_nil(p.og_image_id), order_by: p.title))

    ids = Enum.uniq(Enum.map(areas, & &1.cms_image_id) ++ Enum.map(bios, & &1.cms_image_id) ++ Enum.map(pages, & &1.og_image_id))

    Map.new(ids, fn id ->
      {id,
       usage_items(%{
         areas: Enum.filter(areas, &(&1.cms_image_id == id)),
         bios: Enum.filter(bios, &(&1.cms_image_id == id)),
         pages: Enum.filter(pages, &(&1.og_image_id == id))
       })}
    end)
  end
end
