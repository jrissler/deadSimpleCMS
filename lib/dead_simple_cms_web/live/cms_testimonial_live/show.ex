defmodule DeadSimpleCmsWeb.CmsTestimonialLive.Show do
  @moduledoc "A testimonial as a quote card: the stars, the quote and who said it."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={"Testimonial from #{@cms_testimonial.name}"} sub_title="Testimonial" description={attribution(@cms_testimonial, @cms_testimonial.name)}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_testimonials")}>
          <.icon name="hero-arrow-left" class="size-4" /> All testimonials
        </.button>
        <.button variant="primary" navigate={DeadSimpleCms.path("/cms_testimonials/#{@cms_testimonial.id}/edit?return_to=show")}>
          <.icon name="hero-pencil" class="size-4" /> Edit testimonial
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto grid max-w-5xl gap-6 px-4 sm:px-6 lg:grid-cols-[minmax(0,1fr)_18rem] lg:px-8">
        <figure id="testimonial-card" class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm sm:p-8">
          <.stars count={@cms_testimonial.stars} class="text-2xl" />
          <blockquote class="mt-4 whitespace-pre-line text-lg leading-8 text-zinc-800">“{@cms_testimonial.quote}”</blockquote>
          <figcaption class="mt-6 border-t border-zinc-100 pt-4">
            <p class="font-semibold text-zinc-900">{@cms_testimonial.name}</p>
            <p :if={attribution(@cms_testimonial) != ""} class="text-sm text-zinc-500">{attribution(@cms_testimonial)}</p>
          </figcaption>
        </figure>

        <aside class="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
          <h2 class="text-base font-semibold text-zinc-900">Details</h2>
          <dl class="mt-4 space-y-3 text-sm">
            <div>
              <dt class="text-zinc-500">Status</dt>
              <dd class="mt-1">
                <.status_badge tone={if @cms_testimonial.visible, do: :good, else: :muted}>{if @cms_testimonial.visible, do: "Shown", else: "Hidden"}</.status_badge>
              </dd>
            </div>
            <div>
              <dt class="text-zinc-500">Where it was posted</dt>
              <dd class="mt-1 text-zinc-900">{@cms_testimonial.source || "Not set"}</dd>
            </div>
            <div>
              <dt class="text-zinc-500">Last updated</dt>
              <dd class="mt-1 text-zinc-900">{friendly_date(@cms_testimonial.updated_at)}</dd>
            </div>
          </dl>
        </aside>
      </div>
    </main>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    cms_testimonial = SpecialContent.get_cms_testimonial!(id)

    {:ok, socket |> assign(:page_title, "Testimonial from #{cms_testimonial.name}") |> assign(:cms_testimonial, cms_testimonial)}
  end

  @doc "A star rating, like ★★★★☆, with the number for screen readers."
  attr :count, :integer, default: nil
  attr :class, :any, default: nil

  def stars(assigns) do
    assigns = assign(assigns, :count, assigns.count |> Kernel.||(0) |> max(0) |> min(5))

    ~H"""
    <span class={["tracking-wide", @class]} title={"#{@count} out of 5 stars"}>
      <span aria-hidden="true"><span class="text-amber-500">{String.duplicate("★", @count)}</span><span class="text-zinc-300">{String.duplicate("★", 5 - @count)}</span></span>
      <span class="sr-only">{@count} out of 5 stars</span>
    </span>
    """
  end

  @doc "Their role, company and where it was posted, joined for display: \"Owner, Acme · Google\"."
  def attribution(cms_testimonial, fallback \\ "") do
    who = [cms_testimonial.title, cms_testimonial.company] |> Enum.filter(&present?/1) |> Enum.join(", ")
    line = [who, cms_testimonial.source && "via #{cms_testimonial.source}"] |> Enum.filter(&present?/1) |> Enum.join(" · ")
    if line == "", do: fallback, else: line
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
