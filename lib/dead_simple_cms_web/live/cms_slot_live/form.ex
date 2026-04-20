defmodule DeadSimpleCmsWeb.CmsSlotLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsSlot

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="CMS slots define named render targets that content areas can be assigned to.">
      <:action>
        <.link navigate={DeadSimpleCms.path("/cms_slots")} class="flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-list-bullet" class="-ml-0.5 mr-1 h-5 w-5" /> All CMS Slots
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-slot-form-heading">
            <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
              <.form for={@form} id="cms_slot-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
                <div class="grid grid-cols-1 gap-6">
                  <.input field={@form[:key]} type="text" label="Key" />
                  <.input field={@form[:name]} type="text" label="Name" />
                  <.input field={@form[:description]} type="textarea" label="Description" />
                </div>

                <footer class="flex justify-end gap-3 pt-6 border-t border-zinc-200">
                  <.link navigate={return_path(@return_to, @cms_slot)} class="btn btn-primary btn-soft">
                    Cancel
                  </.link>

                  <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                    Save Cms slot
                  </.button>
                </footer>
              </.form>
            </div>
          </section>
        </div>
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
    cms_slot = Cms.get_cms_slot!(id)

    socket
    |> assign(:page_title, "Edit Cms slot")
    |> assign(:cms_slot, cms_slot)
    |> assign(:form, to_form(Cms.change_cms_slot(cms_slot)))
  end

  defp apply_action(socket, :new, _params) do
    cms_slot = %CmsSlot{}

    socket
    |> assign(:page_title, "New Cms slot")
    |> assign(:cms_slot, cms_slot)
    |> assign(:form, to_form(Cms.change_cms_slot(cms_slot)))
  end

  @impl true
  def handle_event("validate", %{"cms_slot" => cms_slot_params}, socket) do
    changeset = Cms.change_cms_slot(socket.assigns.cms_slot, cms_slot_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_slot" => cms_slot_params}, socket) do
    save_cms_slot(socket, socket.assigns.live_action, cms_slot_params)
  end

  defp save_cms_slot(socket, :edit, cms_slot_params) do
    case Cms.update_cms_slot(socket.assigns.cms_slot, cms_slot_params) do
      {:ok, cms_slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms slot updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_slot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_slot(socket, :new, cms_slot_params) do
    case Cms.create_cms_slot(cms_slot_params) do
      {:ok, cms_slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cms slot created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_slot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _cms_slot), do: DeadSimpleCms.path("/cms_slots")
  defp return_path("show", cms_slot), do: DeadSimpleCms.path("/cms_slots/#{cms_slot.id}")
end
