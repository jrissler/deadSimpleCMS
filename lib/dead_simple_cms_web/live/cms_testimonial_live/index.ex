defmodule DeadSimpleCmsWeb.CmsTestimonialLive.Index do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Listing CMS Testimonials" sub_title="Admin" description="Testimonials represent reusable review content for sections like home pages and carousels.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_testimonials/new")} class="flex items-center justify-center rounded-md bg-green-600 px-3 py-2 text-sm font-semibold text-white hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-plus" class="-ml-0.5 mr-1 h-5 w-5" /> Add CMS Testimonial
        </.link>
      </:action>
    </.content_header>

    <.admin_table id="cms_testimonials" rows={@streams.cms_testimonials} row_click={fn {_id, cms_testimonial} -> JS.navigate(DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}")) end}>
      <:col :let={{_id, cms_testimonial}} label="Name">{cms_testimonial.name}</:col>
      <:col :let={{_id, cms_testimonial}} label="Stars">{cms_testimonial.stars}</:col>
      <:col :let={{_id, cms_testimonial}} label="Visible">{cms_testimonial.visible}</:col>

      <:action :let={{_id, cms_testimonial}}>
        <.link navigate={DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}/edit")}>
          Edit
        </.link>
      </:action>

      <:action :let={{_id, cms_testimonial}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_testimonial.id})} data-confirm="Are you sure?">
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
     |> assign(:page_title, "Listing CMS testimonials")
     |> stream(:cms_testimonials, SpecialContent.list_cms_testimonials())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_testimonial = SpecialContent.get_cms_testimonial!(id)
    {:ok, _} = SpecialContent.delete_cms_testimonial(cms_testimonial)
    {:noreply, stream_delete(socket, :cms_testimonials, cms_testimonial)}
  end
end
