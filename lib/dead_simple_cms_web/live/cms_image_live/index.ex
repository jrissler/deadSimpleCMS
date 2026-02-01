defmodule DeadSimpleCmsWeb.CmsImageLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Images" sub_title="Admin" description="Images are reusable media assets that can be attached to content areas.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_images/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Image
        </.link>
      </:action>
    </.content_header>

    <.admin_table id="cms_images" rows={@streams.cms_images} row_click={fn {_id, image} -> JS.navigate(DeadSimpleCms.path("/cms_images/#{image.id}")) end}>
      <:col :let={{_id, image}} label="Filename">{image.filename}</:col>
      <:col :let={{_id, image}} label="Caption">
        <span class="truncate max-w-xs block">{image.caption}</span>
      </:col>

      <:action :let={{_id, image}}>
        <.link navigate={DeadSimpleCms.path("/cms_images/#{image.id}/edit")}>
          Edit
        </.link>
      </:action>

      <:action :let={{_id, image}}>
        <.link phx-click={JS.push("delete", value: %{id: image.id})} data-confirm="Are you sure?">
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
     |> assign(:page_title, "Listing CMS images")
     |> stream(:cms_images, Cms.list_cms_images())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    image = Cms.get_cms_image!(id)
    {:ok, _} = Cms.delete_cms_image(image)
    {:noreply, stream_delete(socket, :cms_images, image)}
  end
end
