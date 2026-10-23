defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Form do
  @moduledoc """
  Edits one section on its own, outside its page or template editor: where it
  lives, its type, words, image (with its description) and whether it shows.
  """
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea
  alias DeadSimpleCmsWeb.ImageUploads

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title={@live_action == :edit && label(@cms_content_area)} description={header_description(@live_action)}>
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_content_areas")}>
          <.icon name="hero-arrow-left" class="size-4" /> All sections
        </.button>
        <.button :if={@live_action == :edit && owner_path(@cms_content_area)} navigate={owner_path(@cms_content_area)}>
          <.icon name="hero-document-text" class="size-4" /> {if @cms_content_area.cms_page_template_id, do: "Open template", else: "Open page"}
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="section-form-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_content_area-form" phx-change="validate" phx-submit="save" class="space-y-8 p-6 sm:p-8">
              <div class="space-y-5">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <h2 id="section-form-heading" class="text-lg font-semibold tracking-tight text-gray-900">Section</h2>
                  <.status_badge :if={@live_action == :edit} tone={if @cms_content_area.visible, do: :good, else: :dark}>
                    {if @cms_content_area.visible, do: "Shown", else: "Hidden"}
                  </.status_badge>
                </div>

                <div>
                  <.input field={@form[:owner]} type="select" label="Page or template" value={@owner} options={owner_options(@pages, @templates)} prompt="Choose a page or template" />
                  <.hint>Where this section appears. Template sections are copied into new pages, or shown on every page when shared.</.hint>
                </div>

                <div>
                  <.input field={@form[:cms_slot_id]} type="select" label="Section type" options={Enum.map(@cms_slots, &{&1.name, &1.id})} prompt="Choose a section type" />
                  <.hint id="section-type-help" class="whitespace-pre-line">
                    {slot_description(@form, @cms_slots) || "Decides how the website lays this section out."}
                  </.hint>
                </div>

                <.input field={@form[:title]} type="text" label="Title" />
                <.input field={@form[:subtitle]} type="text" label="Subtitle" />

                <div>
                  <.input field={@form[:body_md]} type="textarea" label="Body" rows="10" />
                  <.hint>Markdown: **bold**, *italic*, [a link](https://example.com), and a blank line between paragraphs.</.hint>
                </div>
              </div>

              <div id="section-image" class="space-y-4 border-t border-zinc-200 pt-8">
                <div>
                  <h2 class="text-lg font-semibold tracking-tight text-gray-900">Image</h2>
                  <p class="mt-1 text-sm text-gray-600">Optional.</p>
                </div>

                <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
                  <div class="shrink-0">
                    <img :if={shown_image(@current_image, @remove_image)} src={Cms.image_url(shown_image(@current_image, @remove_image))} alt={shown_image(@current_image, @remove_image).alt || ""} class="h-28 w-44 rounded-lg object-cover ring-1 ring-gray-300" />
                    <div :if={!shown_image(@current_image, @remove_image)} class="grid h-28 w-44 place-items-center rounded-lg bg-zinc-100 text-xs text-zinc-500 ring-1 ring-zinc-200">No image</div>
                    <p :if={shown_image(@current_image, @remove_image) && present(shown_image(@current_image, @remove_image).caption)} class="mt-2 max-w-44 text-xs text-zinc-500">{shown_image(@current_image, @remove_image).caption}</p>
                    <button
                      :if={shown_image(@current_image, @remove_image)}
                      type="button"
                      id="remove-image"
                      phx-click="remove_image"
                      class="mt-2 text-xs font-semibold text-red-600 hover:text-red-500"
                    >
                      Remove image
                    </button>
                    <p :if={@current_image && @remove_image} id="image-removed" class="mt-2 max-w-44 text-xs text-zinc-600">
                      The image comes off when you save. It stays in your image library. <button type="button" phx-click="keep_image" class="font-semibold text-indigo-600 hover:text-indigo-500">Keep it</button>
                    </p>
                  </div>

                  <div class="min-w-0 flex-1 space-y-4">
                    <div class="phx-drop-target rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-4" phx-drop-target={@uploads.image.ref}>
                      <label for={@uploads.image.ref} class="inline-flex cursor-pointer items-center gap-2 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                        <.icon name="hero-arrow-up-tray" class="h-4 w-4 text-gray-500" /> {if shown_image(@current_image, @remove_image), do: "Replace image", else: "Add image"}
                      </label>
                      <.live_file_input upload={@uploads.image} class="sr-only" />
                      <.hint>Or drop a file here. {ImageUploads.accepted_formats()}. It's added when you save the section.</.hint>

                      <div :for={entry <- @uploads.image.entries} class="mt-4 flex items-center gap-4 rounded-lg bg-white p-3 shadow-sm">
                        <.live_img_preview entry={entry} class="h-16 w-24 rounded object-cover" />
                        <div class="min-w-0 flex-1">
                          <p class="truncate text-sm text-gray-700">{entry.client_name}</p>
                          <progress value={entry.progress} max="100" class="mt-1 h-2 w-full rounded-lg bg-blue-100">{entry.progress}%</progress>
                          <p :for={err <- upload_errors(@uploads.image, entry)} class="mt-1 text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                        </div>
                        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-lg font-bold text-red-500 hover:text-red-700" aria-label="Cancel upload">&times;</button>
                      </div>

                      <p :for={err <- upload_errors(@uploads.image)} class="mt-2 text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                    </div>

                    <div :if={shown_image(@current_image, @remove_image) || @uploads.image.entries != []}>
                      <label for="section-image-alt" class="label mb-1">Image description</label>
                      <input type="text" id="section-image-alt" name="image_alt" value={@image_alt} class="input w-full" placeholder="For example: James and Patricia on Empire's bow at sunset" />
                      <.hint>Describes the photo for people using screen readers, and helps search engines. One plain sentence.</.hint>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <div>
                  <.input field={@form[:visible]} type="checkbox" label="Show this section on the page" />
                  <.hint>Uncheck to hide it without deleting it.</.hint>
                </div>

                <div :if={template_owner?(@owner)}>
                  <.input field={@form[:shared]} type="checkbox" label="Shared on every page" />
                  <.hint>Shared sections show on every page that uses this template. Unchecked sections are starters, copied into each new page to edit there.</.hint>
                </div>

                <div>
                  <.input field={@form[:position]} type="number" label="Order" min="0" />
                  <.hint>Sections show lowest number first, so 0 is the top. {if @live_action == :new, do: "Filled in to put the section at the end."}</.hint>
                </div>

                <div>
                  <.input field={@form[:name]} type="text" label="Section name" />
                  <.hint>Only editors see this. It names the section in lists when it has no title, and must be unique on the page.</.hint>
                </div>
              </div>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button
                  :if={@live_action == :edit}
                  type="button"
                  id="delete-section"
                  phx-click="delete"
                  data-confirm={"Delete the section \"#{label(@cms_content_area)}\"? It comes off its page right away. This can't be undone."}
                  class="text-sm font-semibold text-red-600 hover:text-red-500"
                >
                  Delete section
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button navigate={return_path(@return_to, @cms_content_area)}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Create section", else: "Save section"}</.button>
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
     |> assign(:pages, Cms.list_cms_pages() |> Enum.sort_by(&String.downcase(&1.title)))
     |> assign(:templates, Cms.list_cms_page_templates() |> Enum.sort_by(&String.downcase(&1.name)))
     |> assign(:cms_slots, Cms.list_cms_slots() |> Enum.sort_by(&String.downcase(&1.name)))
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:remove_image, false)
     |> ImageUploads.allow_image_upload(:image)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    area = id |> Cms.get_cms_content_area!() |> DeadSimpleCms.repo!().preload([:cms_page, :cms_page_template])

    socket
    |> assign(:page_title, "Edit section")
    |> assign(:cms_content_area, area)
    |> assign(:owner, owner_value(area))
    |> assign(:form, to_form(Cms.change_cms_content_area(area)))
    |> assign(:current_image, area.cms_image)
    |> assign(:image_alt, area.cms_image && area.cms_image.alt)
  end

  defp apply_action(socket, :new, _params) do
    area = %CmsContentArea{visible: true}

    socket
    |> assign(:page_title, "New section")
    |> assign(:cms_content_area, area)
    |> assign(:owner, "")
    |> assign(:form, to_form(Cms.change_cms_content_area(area)))
    |> assign(:current_image, nil)
    |> assign(:image_alt, nil)
  end

  @impl true
  def handle_event("validate", %{"cms_content_area" => params} = all_params, socket) do
    params = prepare(params, socket)

    {:noreply,
     socket
     |> assign(:owner, params["owner"] || socket.assigns.owner)
     |> assign(:image_alt, all_params["image_alt"] || socket.assigns.image_alt)
     |> assign(:form, to_form(changeset(socket, params), action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("remove_image", _params, socket) do
    socket = Enum.reduce(socket.assigns.uploads.image.entries, socket, &cancel_upload(&2, :image, &1.ref))
    {:noreply, assign(socket, :remove_image, true)}
  end

  def handle_event("keep_image", _params, socket) do
    {:noreply, assign(socket, :remove_image, false)}
  end

  def handle_event("delete", _params, socket) do
    area = socket.assigns.cms_content_area
    {:ok, _} = Cms.delete_cms_content_area(area)
    {:noreply, socket |> put_flash(:info, "Section \"#{label(area)}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_content_areas"))}
  end

  def handle_event("save", %{"cms_content_area" => params} = all_params, socket) do
    params = prepare(params, socket)
    alt = present(all_params["image_alt"])
    socket = socket |> assign(:owner, params["owner"] || socket.assigns.owner) |> assign(:image_alt, alt)
    changeset = changeset(socket, params)

    if changeset.valid? do
      save_cms_content_area(socket, socket.assigns.live_action, params, alt)
    else
      {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
    end
  end

  defp save_cms_content_area(socket, action, params, alt) do
    with {:ok, params} <- attach_image(socket, params, alt),
         :ok <- update_image_alt(socket, params, alt),
         {:ok, area} <- persist(socket, action, params) do
      message = if action == :new, do: "Section created", else: "Section saved"
      {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: return_path(socket.assigns.return_to, area))}
    else
      {:error, %Ecto.Changeset{data: %CmsContentArea{}} = changeset} -> {:noreply, assign(socket, :form, to_form(changeset))}
      {:error, _image_changeset} -> {:noreply, put_flash(socket, :error, "The image couldn't be saved. Try the upload again.")}
    end
  end

  defp persist(socket, :edit, params), do: Cms.update_cms_content_area(socket.assigns.cms_content_area, params)
  defp persist(_socket, :new, params), do: Cms.create_cms_content_area(params)

  defp attach_image(socket, params, alt) do
    case ImageUploads.consume_image(socket, :image, alt) do
      {:ok, image} -> {:ok, Map.put(params, "cms_image_id", image.id)}
      :none -> if socket.assigns.remove_image, do: {:ok, Map.put(params, "cms_image_id", nil)}, else: {:ok, params}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # The description typed for the section's current image is saved on that image.
  defp update_image_alt(%{assigns: %{current_image: %{alt: current} = image}}, params, alt) when not is_map_key(params, "cms_image_id") and alt != current do
    case Cms.update_cms_image(image, %{alt: alt}) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp update_image_alt(_socket, _params, _alt), do: :ok

  defp changeset(socket, params) do
    changeset = Cms.change_cms_content_area(socket.assigns.cms_content_area, params)

    if is_nil(Ecto.Changeset.get_field(changeset, :cms_page_id)) and is_nil(Ecto.Changeset.get_field(changeset, :cms_page_template_id)) do
      Ecto.Changeset.add_error(changeset, :owner, "choose a page or template")
    else
      changeset
    end
  end

  # The "Page or template" picker sets one owner and clears the other. Only
  # template sections can be shared. A new section goes at the end of its page.
  defp prepare(params, socket) do
    params
    |> put_owner()
    |> then(fn params -> if template_owner?(params["owner"]), do: params, else: Map.put(params, "shared", "false") end)
    |> then(fn params ->
      owner = owner_tuple(params["owner"])
      if socket.assigns.live_action == :new and blank?(params["position"]) and owner, do: Map.put(params, "position", Cms.next_content_area_position(owner)), else: params
    end)
  end

  defp put_owner(%{"owner" => "page:" <> id} = params), do: Map.merge(params, %{"cms_page_id" => id, "cms_page_template_id" => nil})
  defp put_owner(%{"owner" => "template:" <> id} = params), do: Map.merge(params, %{"cms_page_id" => nil, "cms_page_template_id" => id})
  defp put_owner(%{"owner" => ""} = params), do: Map.merge(params, %{"cms_page_id" => nil, "cms_page_template_id" => nil})
  defp put_owner(params), do: params

  defp owner_tuple("page:" <> id), do: {:page, id}
  defp owner_tuple("template:" <> id), do: {:template, id}
  defp owner_tuple(_owner), do: nil

  defp owner_value(%{cms_page_template_id: id}) when not is_nil(id), do: "template:#{id}"
  defp owner_value(%{cms_page_id: id}) when not is_nil(id), do: "page:#{id}"
  defp owner_value(_area), do: ""

  defp template_owner?(owner), do: is_binary(owner) and String.starts_with?(owner, "template:")

  defp owner_options(pages, templates) do
    [{"Pages", Enum.map(pages, &{&1.title, "page:#{&1.id}"})}, {"Templates", Enum.map(templates, &{"Template: #{&1.name}", "template:#{&1.id}"})}]
    |> Enum.reject(fn {_group, options} -> options == [] end)
  end

  defp owner_path(%{cms_page_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_pages/#{id}/edit")
  defp owner_path(%{cms_page_template_id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_page_templates/#{id}/edit")
  defp owner_path(_area), do: nil

  # The image shown in the form: the current one, unless it's marked for removal.
  defp shown_image(image, false = _remove_image), do: image
  defp shown_image(_image, true), do: nil

  # The selected section type's description, shown as help text (for example, how to fill it in).
  defp slot_description(form, slots) do
    id = Phoenix.HTML.Form.input_value(form, :cms_slot_id)
    Enum.find_value(slots, &(to_string(&1.id) == to_string(id) && present(&1.description)))
  end

  defp header_description(:new), do: "Sections are usually added from their page or template editor. Use this to add one directly."
  defp header_description(:edit), do: "Sections are usually edited from their page or template, where you can see them in order. Changes here show on the site when you save."

  defp label(area), do: present(area.title) || area.name

  defp return_path("show", %CmsContentArea{id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_content_areas/#{id}")
  defp return_path(_return_to, _area), do: DeadSimpleCms.path("/cms_content_areas")

  defp blank?(value), do: value in [nil, ""]

  defp present(value) when value in [nil, ""], do: nil
  defp present(value), do: value
end
