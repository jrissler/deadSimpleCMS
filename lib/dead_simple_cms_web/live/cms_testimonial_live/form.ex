defmodule DeadSimpleCmsWeb.CmsTestimonialLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCms.SpecialContent.CmsTestimonial

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="Testimonials represent reusable review content for sections like home pages and carousels." icon_class="hero-plus">
      <:action>
        <.link patch={DeadSimpleCms.path("/cms_testimonials")} class="flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> All Testimonials
        </.link>
      </:action>
    </.content_header>

    <div class="mt-8 rounded-2xl bg-white shadow-sm ring-1 ring-gray-200">
      <.form for={@form} id="cms_testimonial-form" phx-change="validate" phx-submit="save" class="p-6 sm:p-8">
        <div class="space-y-8">
          <div class="grid grid-cols-1 gap-6">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:company]} type="text" label="Company" />
            <.input field={@form[:source]} type="text" label="Source" />
            <.input field={@form[:quote]} type="textarea" label="Quote" />
            <.input field={@form[:stars]} type="number" label="Stars" min="1" max="5" />
            <div class="pt-1">
              <.input field={@form[:visible]} type="checkbox" label="Visible" />
            </div>
          </div>

          <footer class="flex justify-end gap-3 pt-6">
            <.link navigate={return_path(@return_to, @cms_testimonial)} class="btn btn-primary btn-soft">
              Cancel
            </.link>

            <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
              Save Cms testimonial
            </.button>
          </footer>
        </div>
      </.form>
    </div>
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
    |> assign(:page_title, "Edit Cms testimonial")
    |> assign(:cms_testimonial, cms_testimonial)
    |> assign(:form, to_form(SpecialContent.change_cms_testimonial(cms_testimonial)))
  end

  defp apply_action(socket, :new, _params) do
    cms_testimonial = %CmsTestimonial{}

    socket
    |> assign(:page_title, "New Cms testimonial")
    |> assign(:cms_testimonial, cms_testimonial)
    |> assign(:form, to_form(SpecialContent.change_cms_testimonial(cms_testimonial)))
  end

  @impl true
  def handle_event("validate", %{"cms_testimonial" => cms_testimonial_params}, socket) do
    {:noreply, assign(socket, form: to_form(SpecialContent.change_cms_testimonial(socket.assigns.cms_testimonial, cms_testimonial_params), action: :validate))}
  end

  def handle_event("save", %{"cms_testimonial" => cms_testimonial_params}, socket) do
    save_cms_testimonial(socket, socket.assigns.live_action, cms_testimonial_params)
  end

  defp save_cms_testimonial(socket, :edit, cms_testimonial_params) do
    case SpecialContent.update_cms_testimonial(socket.assigns.cms_testimonial, cms_testimonial_params) do
      {:ok, cms_testimonial} ->
        {:noreply, socket |> put_flash(:info, "Cms testimonial updated successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_testimonial))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_testimonial(socket, :new, cms_testimonial_params) do
    case SpecialContent.create_cms_testimonial(cms_testimonial_params) do
      {:ok, cms_testimonial} ->
        {:noreply, socket |> put_flash(:info, "Cms testimonial created successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_testimonial))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_testimonial), do: DeadSimpleCms.path("/cms_testimonials")
  defp return_path("show", cms_testimonial), do: DeadSimpleCms.path("/cms_testimonials/#{cms_testimonial.id}")
end
