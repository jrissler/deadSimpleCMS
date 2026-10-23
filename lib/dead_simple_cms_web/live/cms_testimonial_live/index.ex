defmodule DeadSimpleCmsWeb.CmsTestimonialLive.Index do
  @moduledoc "All testimonials: who said it, a snippet of the quote, the stars and whether it's shown."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCmsWeb.CmsTestimonialLive.Show

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title="Testimonials" sub_title="Website content" description="Kind words from customers, ready to show on the site. Click a testimonial to edit it.">
      <:action>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_testimonials/new")}>
          <.icon name="hero-plus" class="size-4" /> New testimonial
        </.button>
      </:action>
    </.content_header>

    <.admin_table
      id="cms_testimonials"
      rows={@streams.cms_testimonials}
      row_click={fn {_id, cms_testimonial} -> JS.navigate(DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}/edit")) end}
      empty_title="No testimonials yet"
      empty_description="Add a review or a kind word from a customer to show it on the site."
    >
      <:col :let={{_id, cms_testimonial}} label="Who said it">
        <span class="block">{cms_testimonial.name}</span>
        <span :if={Show.attribution(cms_testimonial) != ""} class="block text-xs font-normal text-zinc-500">{Show.attribution(cms_testimonial)}</span>
      </:col>
      <:col :let={{_id, cms_testimonial}} label="Quote" extra_td_class="max-w-md">
        <span class="block italic text-zinc-600">“{snippet(cms_testimonial.quote)}”</span>
      </:col>
      <:col :let={{_id, cms_testimonial}} label="Rating" extra_td_class="whitespace-nowrap">
        <Show.stars count={cms_testimonial.stars} />
      </:col>
      <:col :let={{_id, cms_testimonial}} label="Status">
        <.status_badge tone={if cms_testimonial.visible, do: :good, else: :muted}>{if cms_testimonial.visible, do: "Shown", else: "Hidden"}</.status_badge>
      </:col>

      <:action :let={{_id, cms_testimonial}}>
        <.link navigate={DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}/edit")}>Edit</.link>
      </:action>
      <:action :let={{_id, cms_testimonial}}>
        <.link navigate={DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}")}>View</.link>
      </:action>
      <:action :let={{_id, cms_testimonial}}>
        <.link phx-click={JS.push("delete", value: %{id: cms_testimonial.id})} data-confirm={"Delete the testimonial from \"#{cms_testimonial.name}\"? This can't be undone."}>
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
     |> assign(:page_title, "Testimonials")
     |> stream(:cms_testimonials, SpecialContent.list_cms_testimonials())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cms_testimonial = SpecialContent.get_cms_testimonial!(id)

    case SpecialContent.delete_cms_testimonial(cms_testimonial) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Testimonial from \"#{cms_testimonial.name}\" deleted") |> stream_delete(:cms_testimonials, cms_testimonial)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "The testimonial from \"#{cms_testimonial.name}\" couldn't be deleted. Try again.")}
    end
  end

  @snippet_length 90

  defp snippet(nil), do: ""

  defp snippet(quote) do
    quote = String.trim(quote)

    if String.length(quote) <= @snippet_length do
      quote
    else
      cut = quote |> String.slice(0, @snippet_length) |> String.replace(~r/\s+\S*$/u, "")
      cut <> "…"
    end
  end
end
