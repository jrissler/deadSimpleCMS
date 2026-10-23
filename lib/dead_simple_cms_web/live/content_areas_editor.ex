defmodule DeadSimpleCmsWeb.ContentAreasEditor do
  @moduledoc """
  The section editor shared by the page and template editors.

      <.live_component module={DeadSimpleCmsWeb.ContentAreasEditor} id="content-areas" owner={{:page, @cms_page.id}} />

  `owner` is `{:page, id}` or `{:template, id}`. The parent LiveView shows the
  editor's messages by handling `{DeadSimpleCmsWeb.ContentAreasEditor, {:flash, kind, message}}`
  with `put_flash/3`. Each section opens to show a
  live preview (through `config :dead_simple_cms, :preview_components`) and its
  fields, and saves on its own. Sections can be added, reordered and deleted
  here, and an image can be uploaded with its description.
  """
  use DeadSimpleCmsWeb, :live_component

  alias DeadSimpleCms.Cms
  alias DeadSimpleCmsWeb.ImageUploads

  @impl true
  def render(assigns) do
    ~H"""
    <section id={@id} aria-labelledby={"#{@id}-heading"}>
      <div class="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 id={"#{@id}-heading"} tabindex="-1" class="text-lg font-semibold tracking-tight text-zinc-900 focus:outline-none">Sections</h2>
          <p class="mt-1 max-w-2xl text-sm text-zinc-600">
            {intro(@owner)}
          </p>
        </div>
        <div class="flex items-center gap-4">
          <div :if={@areas != []} class="flex gap-3 text-sm font-semibold">
            <button type="button" phx-click={JS.set_attribute({"open", "true"}, to: "##{@id}-list > details")} class="text-zinc-600 hover:text-zinc-900">Expand all</button>
            <button type="button" phx-click={JS.remove_attribute("open", to: "##{@id}-list > details")} class="text-zinc-600 hover:text-zinc-900">Collapse all</button>
          </div>
          <.button id={"#{@id}-add"} variant="primary" phx-click="add" phx-target={@myself}>
            <.icon name="hero-plus" class="size-4" /> Add section
          </.button>
        </div>
      </div>

      <div id={"#{@id}-list"} class="mt-4 space-y-3">
        <%!-- open is left to the browser (ignore_attributes) so re-renders don't close it --%>
        <details
          :for={{area, index} <- Enum.with_index(@areas)}
          id={"content-area-#{area.id}"}
          open={area.id == @open_area_id}
          phx-mounted={JS.ignore_attributes(["open"])}
          class="group overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm"
        >
          <summary id={"content-area-#{area.id}-summary"} class="flex cursor-pointer list-none items-center gap-4 px-5 py-4 hover:bg-zinc-50 focus:outline-none focus-visible:bg-zinc-50 [&::-webkit-details-marker]:hidden">
            <span class="w-6 shrink-0 text-sm font-bold tabular-nums text-zinc-400">{index + 1}</span>

            <img :if={area.cms_image} src={Cms.image_url(area.cms_image)} alt="" class="h-10 w-14 shrink-0 rounded object-cover ring-1 ring-zinc-200" />
            <div :if={!area.cms_image} class="h-10 w-14 shrink-0 rounded bg-zinc-100 ring-1 ring-zinc-200"></div>

            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-center gap-2">
                <span class="truncate font-semibold text-zinc-900">{present(area.title) || area.name}</span>
                <.status_badge :if={slot_name(area, @cms_slots)}>{slot_name(area, @cms_slots)}</.status_badge>
                <.status_badge :if={!area.visible} tone={:dark}>Hidden</.status_badge>
                <.status_badge :if={area.shared} tone={:good}>Shared on every page</.status_badge>
                <.status_badge :if={placeholder_image?(area)} tone={:warning}>Placeholder image</.status_badge>
              </div>
              <p :if={present(area.subtitle)} class="mt-0.5 truncate text-sm text-zinc-500">{area.subtitle}</p>
            </div>

            <span :if={dirty?(@area_forms[area.id], @uploads, area.id)} class="flex shrink-0 items-center gap-1.5 text-xs font-semibold text-amber-700">
              <span class="size-2 rounded-full bg-amber-500"></span> Unsaved
            </span>
            <.icon name="hero-chevron-down" class="size-5 shrink-0 text-zinc-400 transition group-open:rotate-180" />
          </summary>

          <div class="border-t border-zinc-200 p-6 sm:p-8">
            <div :if={preview_module()} class="mb-6 overflow-hidden rounded-2xl border border-zinc-200 bg-zinc-50 p-4">
              <p class="mb-3 text-[0.65rem] font-bold uppercase tracking-[0.2em] text-zinc-400">Preview</p>
              {apply(preview_module(), :cms_content_slot, [preview_assigns(area, @area_forms[area.id], @cms_slots)])}
            </div>

            <.form for={@area_forms[area.id]} id={"content-area-form-#{area.id}"} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
              <input type="hidden" name="_id" value={area.id} />

              <div class="grid grid-cols-1 gap-5">
                <div>
                  <.input field={@area_forms[area.id][:cms_slot_id]} id={"content-area-#{area.id}-cms-slot-id"} type="select" label="Section type" options={Enum.map(@cms_slots, &{&1.name, &1.id})} />
                  <.hint :if={slot_description(@area_forms[area.id], @cms_slots)} id={"content-area-#{area.id}-slot-help"} class="whitespace-pre-line">{slot_description(@area_forms[area.id], @cms_slots)}</.hint>
                </div>

                <.input field={@area_forms[area.id][:title]} id={"content-area-#{area.id}-title"} type="text" label="Title" />
                <.input field={@area_forms[area.id][:subtitle]} id={"content-area-#{area.id}-subtitle"} type="text" label="Subtitle" />

                <div class="fieldset">
                  <label for={"content-area-#{area.id}-body-md-input"} class="label mb-1">Body</label>
                  <textarea id={"content-area-#{area.id}-body-md-input"} name={@area_forms[area.id][:body_md].name} class="hidden"><%= Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || "" %></textarea>
                  <div id={"content-area-#{area.id}-body-md-editor-wrapper"} phx-update="ignore">
                    <div id={"content-area-#{area.id}-body-md-editor"} phx-hook="EasyMDE" data-target-input-id={"content-area-#{area.id}-body-md-input"} data-initial-value={Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || ""}></div>
                  </div>
                  <.hint>Markdown: **bold**, *italic*, [a link](https://example.com), and a blank line between paragraphs.</.hint>
                </div>

                <div id={"content-area-#{area.id}-image"} class="fieldset">
                  <span class="label mb-1">Image</span>
                  <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
                    <div class="shrink-0">
                      <img :if={area.cms_image} src={Cms.image_url(area.cms_image)} alt={area.cms_image.alt || ""} class="h-28 w-44 rounded-lg object-cover ring-1 ring-gray-300" />
                      <div :if={!area.cms_image} class="grid h-28 w-44 place-items-center rounded-lg bg-zinc-100 text-xs text-zinc-500 ring-1 ring-zinc-200">No image</div>
                      <p :if={area.cms_image && present(area.cms_image.caption)} class="mt-2 max-w-44 text-xs text-zinc-500">{area.cms_image.caption}</p>
                      <button
                        :if={area.cms_image}
                        type="button"
                        phx-click="remove_image"
                        phx-value-id={area.id}
                        phx-target={@myself}
                        data-confirm="Take the image off this section? The image stays in your image library."
                        class="mt-2 text-xs font-semibold text-red-600 hover:text-red-500"
                      >
                        Remove image
                      </button>
                    </div>

                    <div class="min-w-0 flex-1 space-y-4">
                      <div class="phx-drop-target rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-4" phx-drop-target={@uploads[upload_name(area.id)].ref}>
                        <label for={@uploads[upload_name(area.id)].ref} class="inline-flex cursor-pointer items-center gap-2 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                          <.icon name="hero-arrow-up-tray" class="h-4 w-4 text-gray-500" /> {if area.cms_image, do: "Replace image", else: "Add image"}
                        </label>
                        <.live_file_input upload={@uploads[upload_name(area.id)]} class="sr-only" />
                        <.hint>Or drop a file here. {ImageUploads.accepted_formats()}. It's added when you save the section.</.hint>

                        <div :for={entry <- @uploads[upload_name(area.id)].entries} class="mt-4 flex items-center gap-4 rounded-lg bg-white p-3 shadow-sm">
                          <.live_img_preview entry={entry} class="h-16 w-24 rounded object-cover" />
                          <div class="min-w-0 flex-1">
                            <p class="truncate text-sm text-gray-700">{entry.client_name}</p>
                            <progress value={entry.progress} max="100" class="mt-1 h-2 w-full rounded-lg bg-blue-100">{entry.progress}%</progress>
                            <p :for={err <- upload_errors(@uploads[upload_name(area.id)], entry)} class="mt-1 text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                          </div>
                          <button type="button" phx-click="cancel_upload" phx-value-id={area.id} phx-value-ref={entry.ref} phx-target={@myself} class="text-lg font-bold text-red-500 hover:text-red-700" aria-label="Cancel upload">&times;</button>
                        </div>

                        <p :for={err <- upload_errors(@uploads[upload_name(area.id)])} class="mt-2 text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                      </div>

                      <div :if={area.cms_image || @uploads[upload_name(area.id)].entries != []}>
                        <label for={"content-area-#{area.id}-image-alt"} class="label mb-1">Image description</label>
                        <input
                          type="text"
                          id={"content-area-#{area.id}-image-alt"}
                          name="image_alt"
                          value={@image_alts[area.id]}
                          class="input w-full"
                          placeholder="For example: James and Patricia on Empire's bow at sunset"
                        />
                        <.hint>Describes the photo for people using screen readers, and helps search engines. One plain sentence.</.hint>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <.input field={@area_forms[area.id][:visible]} id={"content-area-#{area.id}-visible"} type="checkbox" label="Show this section on the page" />
                  <.hint>Uncheck to hide it without deleting it.</.hint>
                </div>

                <div :if={match?({:template, _}, @owner)}>
                  <.input field={@area_forms[area.id][:shared]} id={"content-area-#{area.id}-shared"} type="checkbox" label="Shared on every page" />
                  <.hint>Shared sections show on every page that uses this template. Unchecked sections are starters, copied into each new page to edit there.</.hint>
                </div>

                <details class="group/more rounded-lg border border-zinc-200 px-4 py-3">
                  <summary class="cursor-pointer text-sm font-semibold text-zinc-700">More options</summary>
                  <div class="mt-3">
                    <.input field={@area_forms[area.id][:name]} id={"content-area-#{area.id}-name"} type="text" label="Section name" />
                    <.hint>Only editors see this. It names the section in this list when it has no title, and must be unique on the page.</.hint>
                  </div>
                </details>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3 border-t border-zinc-200 pt-5">
                <div class="flex flex-wrap items-center gap-2">
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">Save section</.button>
                  <.button :if={index > 0} id={"content-area-#{area.id}-move-up"} phx-click="move" phx-value-id={area.id} phx-value-direction="up" phx-target={@myself}>
                    <.icon name="hero-arrow-up" class="size-4" /> Move up
                  </.button>
                  <.button :if={index < length(@areas) - 1} id={"content-area-#{area.id}-move-down"} phx-click="move" phx-value-id={area.id} phx-value-direction="down" phx-target={@myself}>
                    <.icon name="hero-arrow-down" class="size-4" /> Move down
                  </.button>
                </div>
                <button
                  type="button"
                  id={"content-area-#{area.id}-delete"}
                  phx-click="delete"
                  phx-value-id={area.id}
                  phx-target={@myself}
                  data-confirm={"Delete the section \"#{present(area.title) || area.name}\"? This can't be undone."}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete section
                </button>
              </div>
            </.form>
          </div>
        </details>

        <div :if={@areas == []} id={"#{@id}-empty"} class="rounded-2xl border border-dashed border-zinc-300 bg-white p-8 text-center shadow-sm">
          <p class="font-semibold text-zinc-900">No sections yet</p>
          <p class="mt-1 text-sm text-zinc-600">Add a section to start building this {owner_noun(@owner)}.</p>
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, open_area_id: nil, area_forms: %{}, image_alts: %{})}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket |> assign(:cms_slots, Cms.list_cms_slots()) |> load_areas()}
  end

  @impl true
  def handle_event("add", _params, socket) do
    owner = socket.assigns.owner

    case default_slot(socket.assigns.cms_slots) do
      nil ->
        {:noreply, flash(socket, :error, "Add a section type (slot) first, then add sections.")}

      slot ->
        attrs = owner_attrs(owner) |> Map.merge(%{position: Cms.next_content_area_position(owner), name: unique_name(socket.assigns.areas), visible: true, cms_slot_id: slot.id})

        case Cms.create_cms_content_area(attrs) do
          {:ok, area} -> {:noreply, socket |> flash(:info, "Section added") |> assign(:open_area_id, area.id) |> load_areas()}
          {:error, _changeset} -> {:noreply, flash(socket, :error, "The section couldn't be added")}
        end
    end
  end

  def handle_event("validate", %{"_id" => id, "cms_content_area" => params} = all_params, socket) do
    area = find_area(socket, id)
    form = area |> Cms.change_cms_content_area(params) |> to_form(action: :validate)

    {:noreply, socket |> put_form(id, form) |> put_alt(id, all_params["image_alt"])}
  end

  def handle_event("save", %{"_id" => id, "cms_content_area" => params} = all_params, socket) do
    area = find_area(socket, id)
    alt = present(all_params["image_alt"])

    with {:ok, params} <- attach_upload(socket, id, params, alt),
         :ok <- update_image_alt(area, params, alt),
         {:ok, _area} <- Cms.update_cms_content_area(area, params) do
      {:noreply, socket |> flash(:info, "Section saved") |> reload_area(id)}
    else
      {:error, %Ecto.Changeset{data: %Cms.CmsContentArea{}} = changeset} -> {:noreply, put_form(socket, id, to_form(changeset))}
      {:error, _image_changeset} -> {:noreply, flash(socket, :error, "The image couldn't be saved. Try the upload again.")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = socket |> find_area(id) |> Cms.delete_cms_content_area()
    {:noreply, socket |> flash(:info, "Section deleted") |> load_areas()}
  end

  def handle_event("move", %{"id" => id, "direction" => direction}, socket) do
    Cms.move_cms_content_area(find_area(socket, id), String.to_existing_atom(direction))
    {:noreply, load_areas(socket)}
  end

  def handle_event("cancel_upload", %{"id" => id, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, upload_name(id), ref)}
  end

  def handle_event("remove_image", %{"id" => id}, socket) do
    {:ok, _} = socket |> find_area(id) |> Cms.update_cms_content_area(%{cms_image_id: nil})
    {:noreply, socket |> flash(:info, "Image removed from the section") |> reload_area(id)}
  end

  # Flash set in a LiveComponent only shows after a navigation, so the parent
  # LiveView shows it: it handles {DeadSimpleCmsWeb.ContentAreasEditor, {:flash, kind, message}}.
  defp flash(socket, kind, message) do
    send(self(), {__MODULE__, {:flash, kind, message}})
    socket
  end

  # Loads the areas in order, keeping the unsaved form of any area already open.
  defp load_areas(socket) do
    areas = Cms.list_owner_content_areas(socket.assigns.owner)

    forms = Map.new(areas, fn area -> {area.id, keep_dirty(socket.assigns.area_forms[area.id], area)} end)
    alts = Map.new(areas, fn area -> {area.id, Map.get(socket.assigns.image_alts, area.id, area.cms_image && area.cms_image.alt)} end)

    socket
    |> assign(areas: areas, area_forms: forms, image_alts: alts)
    |> allow_uploads(areas)
  end

  defp keep_dirty(%Phoenix.HTML.Form{source: %Ecto.Changeset{changes: changes}} = form, _area) when changes != %{}, do: form
  defp keep_dirty(_form, area), do: to_form(Cms.change_cms_content_area(area))

  # After a save, refresh just that area so the others keep their unsaved edits.
  defp reload_area(socket, id) do
    area = socket.assigns.owner |> Cms.list_owner_content_areas() |> Enum.find(&(&1.id == id))
    areas = Enum.map(socket.assigns.areas, &if(&1.id == id, do: area, else: &1))

    socket
    |> assign(:areas, areas)
    |> put_form(id, to_form(Cms.change_cms_content_area(area)))
    |> put_alt(id, area.cms_image && area.cms_image.alt)
  end

  defp allow_uploads(socket, areas), do: Enum.reduce(areas, socket, &ImageUploads.allow_image_upload(&2, upload_name(&1.id)))

  defp attach_upload(socket, id, params, alt) do
    case ImageUploads.consume_image(socket, upload_name(id), alt) do
      :none -> {:ok, params}
      {:ok, image} -> {:ok, Map.put(params, "cms_image_id", image.id)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # The description typed for the section's current image is saved on that image.
  defp update_image_alt(%{cms_image: %{alt: current} = image}, params, alt) when not is_map_key(params, "cms_image_id") and alt != current do
    case Cms.update_cms_image(image, %{alt: alt}) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp update_image_alt(_area, _params, _alt), do: :ok

  defp put_form(socket, id, form), do: assign(socket, :area_forms, Map.put(socket.assigns.area_forms, id, form))
  defp put_alt(socket, id, alt), do: assign(socket, :image_alts, Map.put(socket.assigns.image_alts, id, alt))

  defp find_area(socket, id), do: Enum.find(socket.assigns.areas, &(&1.id == id))

  defp owner_attrs({:page, id}), do: %{cms_page_id: id}
  defp owner_attrs({:template, id}), do: %{cms_page_template_id: id}

  defp owner_noun({:page, _}), do: "page"
  defp owner_noun({:template, _}), do: "template"

  defp intro({:page, _}), do: "The page is built from these sections, top to bottom. Open one to edit it, then save it. Each section saves on its own."

  defp intro({:template, _}),
    do: "Starter sections are copied into each new page made from this template. Shared sections show on every page that uses it. Open one to edit it, then save it."

  defp default_slot(slots), do: Enum.find(slots, &(&1.key == "standard_content")) || List.first(slots)

  defp unique_name(areas) do
    taken = MapSet.new(areas, & &1.name)
    Stream.iterate(length(areas) + 1, &(&1 + 1)) |> Enum.find(&(not MapSet.member?(taken, "section-#{&1}"))) |> then(&"section-#{&1}")
  end

  # Each area gets its own upload, so its file input can live inside that area's form.
  defp upload_name(area_id), do: String.to_atom("area_image_" <> area_id)

  defp dirty?(%Phoenix.HTML.Form{source: %Ecto.Changeset{changes: changes}}, uploads, area_id), do: changes != %{} or match?(%{entries: [_ | _]}, uploads[upload_name(area_id)])
  defp dirty?(_form, _uploads, _area_id), do: false

  defp slot_name(%{cms_slot: %{name: name}}, _slots), do: name
  defp slot_name(%{cms_slot_id: id}, slots), do: Enum.find_value(slots, &(&1.id == id && &1.name))

  # The selected slot's description, shown as help text (for example, how to format its body).
  defp slot_description(form, slots) do
    id = form && Phoenix.HTML.Form.input_value(form, :cms_slot_id)
    Enum.find_value(slots, &(to_string(&1.id) == to_string(id) && present(&1.description)))
  end

  # Images can carry a note like "Placeholder: replace with..." in their caption.
  defp placeholder_image?(%{cms_image: %{caption: caption}}) when is_binary(caption), do: caption =~ ~r/placeholder/i
  defp placeholder_image?(_area), do: false

  defp preview_module do
    module = Application.get_env(:dead_simple_cms, :preview_components)
    if is_atom(module) and not is_nil(module) and Code.ensure_loaded?(module) and function_exported?(module, :cms_content_slot, 1), do: module
  end

  # Called directly rather than through HEEx, so build the assigns a function
  # component expects: `__changed__` lets the host's component use assign/3.
  defp preview_assigns(area, form, slots), do: %{__changed__: nil, content_area: preview_area(area, form, slots)}

  defp preview_area(area, nil, _slots), do: area

  defp preview_area(area, form, slots) do
    slot_id = input_value(form, :cms_slot_id, area.cms_slot_id)

    %{
      area
      | name: input_value(form, :name, area.name),
        visible: input_value(form, :visible, area.visible) in [true, "true"],
        cms_slot_id: slot_id,
        cms_slot: Enum.find(slots, &(to_string(&1.id) == to_string(slot_id))) || area.cms_slot,
        title: input_value(form, :title, area.title),
        subtitle: input_value(form, :subtitle, area.subtitle),
        body_md: input_value(form, :body_md, area.body_md)
    }
  end

  defp input_value(form, field, fallback), do: Phoenix.HTML.Form.input_value(form, field) || fallback

  defp present(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: value)
  defp present(_value), do: nil
end
