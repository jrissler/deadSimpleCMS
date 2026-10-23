defmodule DeadSimpleCmsWeb.CmsSlotLive.Form do
  @moduledoc "Creates and edits a section type (slot): its key for the website's code, and its name and help for editors."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsSlot

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header
      main_title={@page_title}
      sub_title={@live_action == :edit && @cms_slot.name}
      description="Section types are usually set up by your developer: each one matches a layout in the website's code."
    >
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_slots")}>
          <.icon name="hero-arrow-left" class="size-4" /> All section types
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="cms-slot-form-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_slot-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
              <h2 id="cms-slot-form-heading" class="text-lg font-semibold tracking-tight text-gray-900">Section type</h2>

              <div class="grid grid-cols-1 gap-5">
                <div>
                  <.input field={@form[:name]} type="text" label="Name" placeholder="Story with photo" />
                  <.hint>What editors see in the Section type list. Plain words that say what the section looks like.</.hint>
                </div>

                <div>
                  <.input field={@form[:key]} type="text" label="Key" placeholder="story_with_photo" />
                  <.hint>
                    The name the website's code matches on, in lowercase with underscores. {if @usage > 0,
                      do: "Changing it breaks the #{usage_label(@usage)} using this type until the code is updated too.",
                      else: "Ask your developer which key the code expects. Changing it later breaks the sections using it."}
                  </.hint>
                </div>

                <div>
                  <.input field={@form[:description]} type="textarea" label="Help for editors" rows="5" />
                  <.hint>Shown under the Section type list when an editor picks this type. Explain how to fill the section in, for example which fields it uses and how long the body should be.</.hint>
                </div>
              </div>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button
                  :if={@live_action == :edit}
                  type="button"
                  id="delete-cms-slot"
                  phx-click="delete"
                  data-confirm={if @usage == 0, do: "Delete the section type \"#{@cms_slot.name}\"? No sections use it. This can't be undone."}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete section type
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button navigate={return_path(@return_to, @cms_slot)}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">Save section type</.button>
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
    cms_slot = Cms.get_cms_slot!(id)

    socket
    |> assign(:page_title, "Edit section type")
    |> assign(:cms_slot, cms_slot)
    |> assign(:usage, Map.get(Cms.slot_usage_counts(), cms_slot.id, 0))
    |> assign(:form, to_form(Cms.change_cms_slot(cms_slot)))
  end

  defp apply_action(socket, :new, _params) do
    cms_slot = %CmsSlot{}

    socket
    |> assign(:page_title, "New section type")
    |> assign(:cms_slot, cms_slot)
    |> assign(:usage, 0)
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

  # Deleting a type in use would leave its sections with no type (and blank on the site).
  def handle_event("delete", _params, socket) do
    cms_slot = socket.assigns.cms_slot

    case Map.get(Cms.slot_usage_counts(), cms_slot.id, 0) do
      0 ->
        {:ok, _} = Cms.delete_cms_slot(cms_slot)
        {:noreply, socket |> put_flash(:info, "Section type \"#{cms_slot.name}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_slots"))}

      count ->
        {:noreply, socket |> assign(:usage, count) |> put_flash(:error, "\"#{cms_slot.name}\" is used by #{usage_label(count)}. Change their type first.")}
    end
  end

  defp save_cms_slot(socket, :edit, cms_slot_params) do
    case Cms.update_cms_slot(socket.assigns.cms_slot, cms_slot_params) do
      {:ok, cms_slot} ->
        {:noreply,
         socket
         |> put_flash(:info, "Section type saved")
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
         |> put_flash(:info, "Section type \"#{cms_slot.name}\" created")
         |> push_navigate(to: return_path(socket.assigns.return_to, cms_slot))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp usage_label(1), do: "1 section"
  defp usage_label(count), do: "#{count} sections"

  defp return_path("show", %CmsSlot{id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_slots/#{id}")
  defp return_path(_return_to, _cms_slot), do: DeadSimpleCms.path("/cms_slots")
end
