defmodule DeadSimpleCmsWeb.CmsTestimonialLive.Form do
  @moduledoc "Create or edit a testimonial: the quote, who said it and the star rating."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCms.SpecialContent.CmsTestimonial

  @star_options for n <- 5..1//-1, do: {String.duplicate("★", n) <> String.duplicate("☆", 5 - n) <> "  #{n} star" <> if(n == 1, do: "", else: "s"), n}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :star_options, @star_options)

    ~H"""
    <.content_header main_title={@page_title} sub_title={@live_action == :edit && @cms_testimonial.name} description="A quote from a happy customer, with who said it and their star rating.">
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_testimonials")}>
          <.icon name="hero-arrow-left" class="size-4" /> All testimonials
        </.button>
        <.button :if={@live_action == :edit} navigate={DeadSimpleCms.path("/cms_testimonials/#{@cms_testimonial.id}")}>
          <.icon name="hero-eye" class="size-4" /> View testimonial
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="testimonial-quote-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_testimonial-form" phx-change="validate" phx-submit="save" class="space-y-8 p-6 sm:p-8">
              <div class="space-y-5">
                <h2 id="testimonial-quote-heading" class="text-lg font-semibold tracking-tight text-gray-900">What they said</h2>
                <div>
                  <.input field={@form[:quote]} type="textarea" label="Quote" rows="5" />
                  <.hint>Their words, as they wrote or said them. No need to add quotation marks.</.hint>
                </div>
                <div class="sm:max-w-xs">
                  <.input field={@form[:stars]} type="select" label="Star rating" prompt="Choose a rating" options={@star_options} />
                  <.hint>Out of 5. If they didn't give a rating, choose the one that fits their words.</.hint>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <h2 class="text-lg font-semibold tracking-tight text-gray-900">Who said it</h2>
                <div>
                  <.input field={@form[:name]} type="text" label="Their name" placeholder="Jane Smith" />
                  <.hint>How they'd like to be named, like "Jane Smith" or "Jane S."</.hint>
                </div>
                <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
                  <div>
                    <.input field={@form[:title]} type="text" label="Their role" placeholder="Owner" />
                    <.hint>Optional. Their job title or how they know you, like "Owner" or "Charter guest".</.hint>
                  </div>
                  <div>
                    <.input field={@form[:company]} type="text" label="Their company" placeholder="Smith Marine" />
                    <.hint>Optional. Shown next to their role.</.hint>
                  </div>
                </div>
                <div>
                  <.input field={@form[:source]} type="text" label="Where it was posted" placeholder="Google" />
                  <.hint>Optional. Where the review came from, like Google, Facebook, Yelp or an email.</.hint>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <div class="rounded-lg border border-zinc-200 bg-zinc-50 p-4">
                  <.input field={@form[:visible]} type="checkbox" label="Show this testimonial on the site" />
                  <.hint>Uncheck to hide it without deleting it.</.hint>
                </div>
              </div>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button
                  :if={@live_action == :edit}
                  type="button"
                  id="delete-cms-testimonial"
                  phx-click="delete"
                  data-confirm={"Delete the testimonial from \"#{@cms_testimonial.name}\"? This can't be undone."}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete testimonial
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button navigate={return_path(@return_to, @cms_testimonial)}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Create testimonial", else: "Save testimonial"}</.button>
                </div>
              </div>
            </.form>
          </div>
        </section>
      </div>
    </main>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_testimonial = SpecialContent.get_cms_testimonial!(id)

    socket
    |> assign(:page_title, "Edit testimonial")
    |> assign(:cms_testimonial, cms_testimonial)
    |> assign(:form, to_form(SpecialContent.change_cms_testimonial(cms_testimonial)))
  end

  defp apply_action(socket, :new, _params) do
    cms_testimonial = %CmsTestimonial{stars: 5}

    socket
    |> assign(:page_title, "New testimonial")
    |> assign(:cms_testimonial, cms_testimonial)
    |> assign(:form, to_form(SpecialContent.change_cms_testimonial(cms_testimonial)))
  end

  @impl true
  def handle_event("validate", %{"cms_testimonial" => cms_testimonial_params}, socket) do
    changeset = SpecialContent.change_cms_testimonial(socket.assigns.cms_testimonial, cms_testimonial_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_testimonial" => cms_testimonial_params}, socket) do
    save_cms_testimonial(socket, socket.assigns.live_action, cms_testimonial_params)
  end

  def handle_event("delete", _params, socket) do
    cms_testimonial = socket.assigns.cms_testimonial

    case SpecialContent.delete_cms_testimonial(cms_testimonial) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Testimonial from \"#{cms_testimonial.name}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_testimonials"))}
      {:error, _} -> {:noreply, put_flash(socket, :error, "The testimonial from \"#{cms_testimonial.name}\" couldn't be deleted. Try again.")}
    end
  end

  defp save_cms_testimonial(socket, :edit, cms_testimonial_params) do
    case SpecialContent.update_cms_testimonial(socket.assigns.cms_testimonial, cms_testimonial_params) do
      {:ok, cms_testimonial} -> {:noreply, socket |> put_flash(:info, "Testimonial saved") |> push_navigate(to: return_path(socket.assigns.return_to, cms_testimonial))}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_testimonial(socket, :new, cms_testimonial_params) do
    case SpecialContent.create_cms_testimonial(cms_testimonial_params) do
      {:ok, cms_testimonial} -> {:noreply, socket |> put_flash(:info, "Testimonial created") |> push_navigate(to: return_path(socket.assigns.return_to, cms_testimonial))}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("show", %CmsTestimonial{id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_testimonials/#{id}")
  defp return_path(_return_to, _cms_testimonial), do: DeadSimpleCms.path("/cms_testimonials")
end
