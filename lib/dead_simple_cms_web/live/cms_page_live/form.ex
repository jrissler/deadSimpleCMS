defmodule DeadSimpleCmsWeb.CmsPageLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCms.Uploaders.S3Uploader

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="Edit CMS Page Settings">
      <:action>
        <.preview_page_link :if={@live_action == :edit} cms_page={@cms_page} class="mr-2" />
        <.link patch={DeadSimpleCms.path("/cms_pages")} class="flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> All CMS Pages
        </.link>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="max-w-6xl mx-auto sm:px-6 lg:px-8">
        <div class={["px-4 sm:px-0", @live_action == :edit && "xl:grid xl:grid-cols-[13rem_minmax(0,1fr)] xl:gap-8"]}>
          <aside :if={@live_action == :edit} class="hidden xl:block">
            <nav id="cms-page-outline" aria-label="Page sections" class="sticky top-6 space-y-0.5 text-sm">
              <div class="px-2 pb-1 text-[0.65rem] font-bold uppercase tracking-[0.2em] text-zinc-400">On this page</div>
              <button type="button" phx-click={JS.focus(to: "#page-settings-heading")} class="flex w-full rounded-md px-2 py-1.5 text-left text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900">Page settings</button>
              <button type="button" phx-click={JS.focus(to: "#page-seo-heading")} class="flex w-full rounded-md px-2 py-1.5 text-left text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900">SEO</button>

              <div class="px-2 pb-1 pt-4 text-[0.65rem] font-bold uppercase tracking-[0.2em] text-zinc-400">Content areas</div>
              <button
                :for={area <- @areas}
                type="button"
                id={"outline-#{area.id}"}
                phx-click={JS.set_attribute({"open", "true"}, to: "#content-area-#{area.id}") |> JS.focus(to: "#content-area-#{area.id}-summary")}
                class="flex w-full items-center gap-2 rounded-md px-2 py-1.5 text-left text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900"
              >
                <span class="w-5 shrink-0 text-xs tabular-nums text-zinc-400">{area.position}</span>
                <span class="truncate">{area.name || "(unnamed)"}</span>
                <span :if={area_dirty?(@area_forms[area.id], @uploads, area.id)} class="ml-auto size-2 shrink-0 rounded-full bg-amber-500" title="Unsaved changes"></span>
              </button>
            </nav>
          </aside>

          <div class="min-w-0 space-y-10">
            <section aria-labelledby="page-settings-heading">
              <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
                <.form for={@form} id="cms_page-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
                  <h2 id="page-settings-heading" tabindex="-1" class="text-base font-semibold tracking-tight text-gray-900 focus:outline-none">Page settings</h2>

                  <div class="grid grid-cols-1 gap-6">
                    <.input field={@form[:slug]} type="text" label="Slug" />
                    <.input field={@form[:title]} type="text" label="Title" />
                    <.input field={@form[:published]} type="checkbox" label="Published" />
                    <.input field={@form[:published_at]} type="datetime-local" label="Published at" />
                    <div>
                      <.input field={@form[:cms_page_template_id]} type="select" label="Page Template (Optional)" options={[{"Select a template", nil}] ++ Enum.map(@cms_page_templates, &{&1.name, &1.id})} />
                      <p :if={@live_action == :new} class="mt-1 text-xs text-gray-500">A new page starts with a copy of the template's sections.</p>
                    </div>
                  </div>

                  <div class="border-t border-zinc-200 pt-6">
                    <h2 id="page-seo-heading" tabindex="-1" class="text-base font-semibold tracking-tight text-gray-900 focus:outline-none">SEO</h2>
                    <p class="mt-1 text-sm text-gray-600">Optional. Controls how this page appears in search results and when shared.</p>

                    <div class="mt-4 grid grid-cols-1 gap-6">
                      <div>
                        <.input field={@form[:meta_title]} type="text" label="Meta title" />
                        <p class="mt-1 text-xs text-gray-500">{char_count(@form, :meta_title)} characters. Aim for 60 or fewer. Falls back to the page title when blank.</p>
                      </div>

                      <div>
                        <.input field={@form[:meta_description]} type="textarea" label="Meta description" />
                        <p class="mt-1 text-xs text-gray-500">{char_count(@form, :meta_description)} characters. Aim for 150–160.</p>
                      </div>

                      <.input field={@form[:og_image_id]} type="select" label="Social share image" options={[{"None", nil}] ++ Enum.map(@cms_images, &{&1.alt || &1.filename, &1.id})} />

                      <div>
                        <.input field={@form[:noindex]} type="checkbox" label="Hide from search engines (noindex)" />
                        <p class="mt-1 text-xs text-gray-500">Noindex pages are also left out of the sitemap.</p>
                      </div>
                    </div>
                  </div>

                  <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:justify-end">
                    <.link navigate={return_path(@return_to, @cms_page)} class="inline-flex items-center justify-center rounded-md border border-gray-300 bg-gray-200 px-4 py-2 text-sm font-semibold text-gray-700 hover:bg-gray-300 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-gray-500">
                      Cancel
                    </.link>

                    <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                      Save CMS Page
                    </.button>
                  </div>
                </.form>
              </div>
            </section>

            <%= if @live_action == :edit do %>
              <section aria-labelledby="cms-page-content-areas-heading">
                <.content_header main_title="Content Areas" sub_title="Page Content" description="Edit content areas for this CMS page.">
                  <:action>
                    <button type="button" phx-click="add_area" class="btn btn-primary">
                      Add Content Area
                    </button>
                  </:action>
                </.content_header>

                <div :if={@areas != []} class="mt-6 flex justify-end gap-4 text-sm font-semibold">
                  <button type="button" phx-click={JS.set_attribute({"open", "true"}, to: "#content-areas > details")} class="text-zinc-600 hover:text-zinc-900">Expand all</button>
                  <button type="button" phx-click={JS.remove_attribute("open", to: "#content-areas > details")} class="text-zinc-600 hover:text-zinc-900">Collapse all</button>
                </div>

                <div id="content-areas" class="space-y-3 mt-3">
                  <%= for area <- @areas do %>
                    <%!-- open is left to the browser (ignore_attributes) so re-renders don't close it --%>
                    <details id={"content-area-#{area.id}"} open={area.id == @open_area_id} phx-mounted={JS.ignore_attributes(["open"])} class="group overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
                      <summary id={"content-area-#{area.id}-summary"} class="flex cursor-pointer list-none items-center gap-4 px-5 py-4 hover:bg-zinc-50 focus:outline-none focus-visible:bg-zinc-50 [&::-webkit-details-marker]:hidden">
                        <span class="w-6 shrink-0 text-sm font-bold tabular-nums text-zinc-400">{area.position}</span>

                        <img :if={area.cms_image} src={area.cms_image.url} alt="" class="h-10 w-14 shrink-0 rounded object-cover ring-1 ring-zinc-200" />
                        <div :if={!area.cms_image} class="h-10 w-14 shrink-0 rounded bg-zinc-100 ring-1 ring-zinc-200"></div>

                        <div class="min-w-0 flex-1">
                          <div class="flex flex-wrap items-center gap-2">
                            <span class="truncate font-semibold text-zinc-900">{area.name || "(unnamed)"}</span>
                            <span :if={slot_name(area, @cms_slots)} class="rounded-full bg-zinc-100 px-2 py-0.5 text-xs font-medium text-zinc-600">{slot_name(area, @cms_slots)}</span>
                            <span :if={!area.visible} class="rounded-full bg-zinc-800 px-2 py-0.5 text-xs font-medium text-white">Hidden</span>
                            <span :if={placeholder_image?(area)} class="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-800">Placeholder image</span>
                          </div>
                          <p :if={area.title} class="mt-0.5 truncate text-sm text-zinc-500">{area.title}</p>
                        </div>

                        <span :if={area_dirty?(@area_forms[area.id], @uploads, area.id)} class="flex shrink-0 items-center gap-1.5 text-xs font-semibold text-amber-700">
                          <span class="size-2 rounded-full bg-amber-500"></span> Unsaved
                        </span>
                        <.icon name="hero-chevron-down" class="size-5 shrink-0 text-zinc-400 transition group-open:rotate-180" />
                      </summary>

                      <div class="border-t border-zinc-200 p-6 sm:p-8">
                        <%= if preview_enabled?() and function_exported?(preview_component_module(), :cms_content_slot, 1) do %>
                          <div class="mb-6 rounded-2xl border border-zinc-200 bg-zinc-50 p-6">
                            {apply(preview_component_module(), :cms_content_slot, [preview_assigns(area, @area_forms[area.id], @cms_slots)])}
                          </div>
                        <% end %>

                        <.form for={@area_forms[area.id]} id={"content-area-form-#{area.id}"} phx-change="validate_area" phx-submit="save_area" class="space-y-6">
                          <input type="hidden" name="_id" value={area.id} />

                          <div class="grid grid-cols-1 gap-4">
                            <.input field={@area_forms[area.id][:name]} id={"content-area-#{area.id}-name"} type="text" label="Name" />
                            <div>
                              <.input field={@area_forms[area.id][:cms_slot_id]} id={"content-area-#{area.id}-cms-slot-id"} type="select" label="Slot" options={[{"Select a slot", nil}] ++ Enum.map(@cms_slots, &{&1.name, &1.id})} />
                              <p :if={slot_description(@area_forms[area.id], @cms_slots)} id={"content-area-#{area.id}-slot-help"} class="mt-1 whitespace-pre-line text-xs text-gray-500">{slot_description(@area_forms[area.id], @cms_slots)}</p>
                            </div>
                            <.input field={@area_forms[area.id][:visible]} id={"content-area-#{area.id}-visible"} type="checkbox" label="Visible" />
                            <.input field={@area_forms[area.id][:position]} id={"content-area-#{area.id}-position"} type="number" label="Position" />
                            <.input field={@area_forms[area.id][:title]} id={"content-area-#{area.id}-title"} type="text" label="Title" />
                            <.input field={@area_forms[area.id][:subtitle]} id={"content-area-#{area.id}-subtitle"} type="text" label="Subtitle" />

                            <div class="space-y-2 fieldset">
                              <label for={"content-area-#{area.id}-body-md-input"} class="label mb-1">
                                Body (Markdown)
                              </label>

                              <textarea id={"content-area-#{area.id}-body-md-input"} name={@area_forms[area.id][:body_md].name} class="hidden"><%= Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || "" %></textarea>

                              <div id={"content-area-#{area.id}-body-md-editor-wrapper"} phx-update="ignore">
                                <div id={"content-area-#{area.id}-body-md-editor"} phx-hook="EasyMDE" data-target-input-id={"content-area-#{area.id}-body-md-input"} data-initial-value={Phoenix.HTML.Form.input_value(@area_forms[area.id], :body_md) || ""}></div>
                              </div>
                            </div>

                            <div id={"content-area-#{area.id}-image"} class="space-y-2 fieldset">
                              <span class="label mb-1">Image</span>

                              <div class="flex flex-col gap-4 sm:flex-row sm:items-start">
                                <div class="shrink-0">
                                  <img :if={area.cms_image} src={area.cms_image.url} alt={area.cms_image.alt || ""} class="h-28 w-44 rounded-lg object-cover ring-1 ring-gray-300" />
                                  <div :if={!area.cms_image} class="grid h-28 w-44 place-items-center rounded-lg bg-zinc-100 text-xs text-zinc-500 ring-1 ring-zinc-200">No image</div>
                                  <p :if={area.cms_image && area.cms_image.caption} class="mt-2 max-w-44 text-xs text-zinc-500">{area.cms_image.caption}</p>
                                  <button :if={area.cms_image} type="button" phx-click="remove_area_image" phx-value-id={area.id} data-confirm="Remove the image from this content area?" class="mt-2 text-xs font-semibold text-red-600 hover:text-red-500">
                                    Remove image
                                  </button>
                                </div>

                                <div class="phx-drop-target flex-1 rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-4" phx-drop-target={@uploads[area_upload(area.id)].ref}>
                                  <label for={@uploads[area_upload(area.id)].ref} class="inline-flex cursor-pointer items-center gap-2 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                                    <.icon name="hero-arrow-up-tray" class="h-4 w-4 text-gray-500" /> {if area.cms_image, do: "Replace image", else: "Add image"}
                                  </label>
                                  <.live_file_input upload={@uploads[area_upload(area.id)]} class="sr-only" />
                                  <p class="mt-2 text-xs text-gray-500">Or drop a file here. It's applied to this content area when you save the area.</p>

                                  <div :for={entry <- @uploads[area_upload(area.id)].entries} class="mt-4 flex items-center gap-4 rounded-lg bg-white p-3 shadow-sm">
                                    <.live_img_preview entry={entry} class="h-16 w-24 rounded object-cover" />
                                    <div class="min-w-0 flex-1">
                                      <p class="truncate text-sm text-gray-700">{entry.client_name}</p>
                                      <progress value={entry.progress} max="100" class="mt-1 h-2 w-full rounded-lg bg-blue-100">{entry.progress}%</progress>
                                      <p :for={err <- upload_errors(@uploads[area_upload(area.id)], entry)} class="mt-1 text-xs text-red-500">{error_to_string(err)}</p>
                                    </div>
                                    <button type="button" phx-click="cancel_area_upload" phx-value-id={area.id} phx-value-ref={entry.ref} class="text-lg font-bold text-red-500 hover:text-red-700" aria-label="cancel">&times;</button>
                                  </div>

                                  <p :for={err <- upload_errors(@uploads[area_upload(area.id)])} class="mt-2 text-xs text-red-500">{error_to_string(err)}</p>
                                </div>
                              </div>
                            </div>
                          </div>

                          <div class="mt-4 flex gap-2">
                            <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
                              Save Area
                            </.button>
                          </div>
                        </.form>
                      </div>
                    </details>
                  <% end %>

                  <%= if Enum.empty?(@areas) do %>
                    <div class="rounded-2xl border border-dashed border-zinc-300 bg-white p-6 text-sm text-zinc-600 shadow-sm">
                      No content areas exist for this page yet.
                    </div>
                  <% end %>
                </div>
              </section>
            <% end %>
          </div>
        </div>
      </div>
    </main>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign(:return_to, return_to(params["return_to"])) |> assign(:open_area_id, nil) |> assign(:cms_page_templates, Cms.list_cms_page_templates()) |> assign(:cms_images, Cms.list_cms_images()) |> assign(:cms_slots, Cms.list_cms_slots()) |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_page = Cms.get_cms_page!(id)
    areas = Enum.sort_by(cms_page.cms_content_areas, & &1.position)

    socket
    |> assign(:page_title, "Edit CMS Page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, areas)
    |> assign(:area_forms, build_area_forms(areas))
    |> allow_area_uploads(areas)
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  defp apply_action(socket, :new, _params) do
    cms_page = %CmsPage{}

    socket
    |> assign(:page_title, "New CMS Page")
    |> assign(:cms_page, cms_page)
    |> assign(:areas, [])
    |> assign(:area_forms, %{})
    |> assign(:form, to_form(Cms.change_cms_page(cms_page)))
  end

  @impl true
  def handle_event("validate", %{"cms_page" => cms_page_params}, socket) do
    changeset = Cms.change_cms_page(socket.assigns.cms_page, cms_page_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"cms_page" => cms_page_params}, socket) do
    save_cms_page(socket, socket.assigns.live_action, cms_page_params)
  end

  def handle_event("validate_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)
    changeset = Cms.change_cms_content_area(content_area, params)
    updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset, action: :validate))

    {:noreply, assign(socket, area_forms: updated_area_forms)}
  end

  def handle_event("add_area", _params, socket) do
    attrs = %{cms_page_id: socket.assigns.cms_page.id, position: Enum.count(socket.assigns.areas) + 1, name: "New Content Area", visible: true, cms_slot_id: List.first(socket.assigns.cms_slots).id}

    case Cms.create_cms_content_area(attrs) do
      {:ok, content_area} ->
        cms_page = Cms.get_cms_page!(socket.assigns.cms_page.id)

        {:noreply, socket |> put_flash(:info, "Content area added") |> assign(:open_area_id, content_area.id) |> assign(:cms_page, cms_page) |> assign(:areas, cms_page.cms_content_areas) |> assign(:area_forms, build_area_forms(cms_page.cms_content_areas)) |> allow_area_uploads(cms_page.cms_content_areas)}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, put_flash(socket, :error, "Content area could not be added")}
    end
  end

  def handle_event("save_area", %{"_id" => id, "cms_content_area" => params}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)
    params = merge_area_image(socket, id, params)

    case Cms.update_cms_content_area(content_area, params) do
      {:ok, _updated_content_area} ->
        {:noreply, socket |> put_flash(:info, "Content area saved") |> replace_area(id)}

      {:error, %Ecto.Changeset{} = changeset} ->
        updated_area_forms = Map.put(socket.assigns.area_forms, content_area.id, to_form(changeset))
        {:noreply, assign(socket, area_forms: updated_area_forms)}
    end
  end

  def handle_event("cancel_area_upload", %{"id" => id, "ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, area_upload(id), ref)}
  end

  def handle_event("remove_area_image", %{"id" => id}, socket) do
    content_area = Enum.find(socket.assigns.areas, fn area -> area.id == id end)
    {:ok, _} = Cms.update_cms_content_area(content_area, %{cms_image_id: nil})

    {:noreply, socket |> put_flash(:info, "Image removed") |> replace_area(id)}
  end

  # Edited since the last save: the changeset has changes, or a file is waiting to upload.
  defp area_dirty?(%Phoenix.HTML.Form{source: %Ecto.Changeset{changes: changes}}, uploads, area_id) do
    changes != %{} or match?(%{entries: [_ | _]}, uploads[area_upload(area_id)])
  end

  defp area_dirty?(_form, _uploads, _area_id), do: false

  defp slot_name(%{cms_slot: %{name: name}}, _cms_slots), do: name
  defp slot_name(%{cms_slot_id: id}, cms_slots), do: Enum.find_value(cms_slots, &(&1.id == id && &1.name))

  # The selected slot's description, shown as help text (for example, how to format its body).
  defp slot_description(form, cms_slots) do
    id = form && Phoenix.HTML.Form.input_value(form, :cms_slot_id)
    Enum.find_value(cms_slots, &(to_string(&1.id) == to_string(id) && &1.description not in [nil, ""] && &1.description))
  end

  # Images can carry a note like "Placeholder: replace with..." in their caption.
  defp placeholder_image?(%{cms_image: %{caption: caption}}) when is_binary(caption), do: caption =~ ~r/placeholder/i
  defp placeholder_image?(_area), do: false

  # Each content area gets its own upload, named after the area, so its file input
  # can live inside that area's form.
  defp area_upload(area_id), do: String.to_atom("area_image_" <> area_id)

  defp allow_area_uploads(socket, areas) do
    Enum.reduce(areas, socket, fn area, socket ->
      name = area_upload(area.id)

      if Map.has_key?(socket.assigns[:uploads] || %{}, name) do
        socket
      else
        allow_upload(socket, name, accept: ~w(.jpg .jpeg .png .gif .webp .heic .heif .bmp .tiff), max_entries: 1, max_file_size: 20_000_000, external: &presign_upload/2)
      end
    end)
  end

  # A file waiting in the area's upload becomes a new CMS image assigned to just this area.
  defp merge_area_image(socket, area_id, params) do
    uploaded =
      consume_uploaded_entries(socket, area_upload(area_id), fn %{public_url: url}, entry ->
        {:ok, %{"filename" => entry.client_name, "url" => url, "size" => entry.client_size, "content_type" => entry.client_type}}
      end)

    case uploaded do
      [image_attrs | _] ->
        {:ok, image} = Cms.create_cms_image(image_attrs)
        Map.put(params, "cms_image_id", image.id)

      [] ->
        params
    end
  end

  # Reloads one area (with its image and slot) after a save, keeping unsaved edits in the others.
  defp replace_area(socket, area_id) do
    reloaded = socket.assigns.cms_page.id |> Cms.get_cms_page!() |> Map.fetch!(:cms_content_areas) |> Enum.find(&(&1.id == area_id))
    areas = Enum.map(socket.assigns.areas, fn area -> if area.id == area_id, do: reloaded, else: area end)

    socket
    |> assign(:areas, areas)
    |> assign(:area_forms, Map.put(socket.assigns.area_forms, area_id, to_form(Cms.change_cms_content_area(reloaded))))
  end

  defp presign_upload(entry, socket) do
    case S3Uploader.generate_presigned_url(entry.client_name, entry.client_type) do
      {:ok, upload_url, public_url, key} ->
        {:ok, %{uploader: "S3", url: upload_url, headers: %{"content-type" => entry.client_type, "x-amz-acl" => "public-read", "acl" => "public-read"}, fields: %{}, public_url: public_url, key: key}, socket}

      {:error, reason} ->
        {:error, reason, socket}
    end
  end

  defp error_to_string({:too_large, %{max_size: max_size}}), do: "File is too large (maximum size is #{div(max_size, 1_000_000)} MB)"
  defp error_to_string({:not_accepted, %{accepted_types: types}}), do: "Only files of type: #{Enum.join(types, ", ")} are allowed"
  defp error_to_string(:external_client_failure), do: "Upload failed: client could not complete upload."
  defp error_to_string(:external_upload_failure), do: "Upload failed: server could not process upload."
  defp error_to_string(error), do: "Unexpected error: #{inspect(error)}"

  defp build_area_forms(cms_content_areas) do
    Enum.reduce(cms_content_areas, %{}, fn cms_content_area, forms_by_id -> Map.put(forms_by_id, cms_content_area.id, to_form(Cms.change_cms_content_area(cms_content_area))) end)
  end

  defp save_cms_page(socket, :edit, cms_page_params) do
    case Cms.update_cms_page(socket.assigns.cms_page, cms_page_params) do
      {:ok, cms_page} ->
        {:noreply, socket |> put_flash(:info, "Cms page updated successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_page(socket, :new, cms_page_params) do
    case Cms.create_cms_page(cms_page_params) do
      {:ok, cms_page} ->
        socket =
          case Cms.copy_template_areas_to_page(cms_page) do
            {:ok, _copied} -> put_flash(socket, :info, "Cms page created successfully")
            {:error, _area_changeset} -> put_flash(socket, :error, "Page created, but its template's sections couldn't be copied")
          end

        {:noreply, push_navigate(socket, to: return_path(socket.assigns.return_to, cms_page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp char_count(form, field), do: form |> Phoenix.HTML.Form.input_value(field) |> to_string() |> String.length()

  defp return_path("index", _cms_page), do: DeadSimpleCms.path("/cms_pages")
  defp return_path("show", cms_page), do: DeadSimpleCms.path("/cms_pages/#{cms_page.id}")

  defp preview_component_module do
    Application.get_env(:dead_simple_cms, :preview_components)
  end

  defp preview_enabled? do
    match?(module when is_atom(module), preview_component_module())
  end

  # Called directly rather than through HEEx, so build the assigns a function
  # component expects: `__changed__` lets the host's component use assign/3.
  defp preview_assigns(area, form, cms_slots), do: %{__changed__: nil, content_area: preview_area(area, form, cms_slots)}

  defp preview_area(area, nil, _cms_slots), do: area

  defp preview_area(area, form, cms_slots) do
    cms_slot_id = input_value(form, :cms_slot_id, area.cms_slot_id)

    %{area | name: input_value(form, :name, area.name), position: input_value(form, :position, area.position), visible: input_value(form, :visible, area.visible), cms_slot_id: cms_slot_id, cms_slot: Enum.find(cms_slots, fn slot -> slot.id == cms_slot_id end) || area.cms_slot, title: input_value(form, :title, area.title), subtitle: input_value(form, :subtitle, area.subtitle), body_md: input_value(form, :body_md, area.body_md)}
  end

  defp input_value(form, field, fallback) do
    Phoenix.HTML.Form.input_value(form, field) || fallback
  end
end
