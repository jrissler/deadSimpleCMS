defmodule DeadSimpleCmsWeb.CmsContentAreaLive.Form do
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsContentArea
  alias DeadSimpleCms.Uploaders.S3Uploader

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Admin" description="Content Areas belong to a Page, and house a specific piece of content." icon_class="hero-plus">
      <:action>
        <.link patch={DeadSimpleCms.path("/cms_content_areas")} class="flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          <.icon name="hero-pencil" class="-ml-0.5 mr-1 h-5 w-5" /> All Content Areas
        </.link>
      </:action>
    </.content_header>

    <div class="mt-8 rounded-2xl bg-white shadow-sm ring-1 ring-gray-200">
      <.form for={@form} id="cms_content_area-form" phx-change="validate" phx-submit="save" class="p-6 sm:p-8">
        <div class="space-y-8">
          <div class="grid grid-cols-1 gap-6">
            <.input field={@form[:cms_page_id]} type="select" label="Page" options={@pages} prompt="Select a page" />
            <.input field={@form[:cms_slot_id]} type="select" label="Slot (template)" options={@cms_slots} prompt="Select a slot (template)" />
            <.input field={@form[:cms_image_id]} type="hidden" />
            <.input field={@form[:position]} type="number" label="Position" />
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:subtitle]} type="text" label="Subtitle" />
            <.input field={@form[:body_md]} type="textarea" label="Body md" />
            <div class="pt-1">
              <.input field={@form[:visible]} type="checkbox" label="Visible" />
            </div>
          </div>

          <div class="border-t border-gray-200 pt-8">
            <div class="flex items-start justify-between gap-6">
              <div>
                <h2 class="text-base font-semibold tracking-tight text-gray-900">Image</h2>
                <p class="mt-1 text-sm text-gray-600">Optional.</p>
              </div>
            </div>

            <%= if @current_image do %>
              <div class="mt-4 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                <div class="flex items-start gap-4">
                  <img src={@current_image.url} alt={@current_image.alt || ""} class="h-28 w-28 object-cover rounded-lg ring-1 ring-gray-300" />
                  <div class="flex-1 space-y-1">
                    <p class="text-sm text-gray-700"><span class="font-semibold text-gray-900">Filename:</span> {@current_image.filename}</p>
                    <p class="text-sm text-gray-700"><span class="font-semibold text-gray-900">Content-Type:</span> {@current_image.content_type}</p>
                    <p class="text-sm text-gray-700"><span class="font-semibold text-gray-900">Size:</span> {@current_image.size}</p>
                    <p :if={@current_image.caption} class="text-sm text-gray-700"><span class="font-semibold text-gray-900">Caption:</span> {@current_image.caption}</p>
                  </div>
                </div>
              </div>
            <% else %>
              <p class="mt-3 text-sm text-gray-600 italic">No image assigned to this content area.</p>
            <% end %>

            <div class="mt-6 flex flex-col items-center p-6 bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg">
              <div class="mb-4 w-full flex items-center justify-center">
                <label for={@uploads.image.ref} class="inline-flex items-center gap-2 rounded-md bg-white px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 shadow-sm hover:bg-gray-50 cursor-pointer focus-within:outline focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-indigo-600">
                  <.icon name="hero-arrow-up-tray" class="h-5 w-5 text-gray-500" /> Choose image
                </label>

                <.live_file_input upload={@uploads.image} class="sr-only" />
              </div>

              <section class="phx-drop-target w-full h-44 flex flex-col items-center justify-center border-2 border-dashed border-gray-300 rounded-lg bg-gray-100 hover:bg-gray-200 transition duration-200 mb-6 p-4" phx-drop-target={@uploads.image.ref}>
                <p class="text-gray-500 text-center">Drop your file here or click Choose image.</p>
                <p class="text-gray-400 text-xs mt-1">1 image per content area (for now).</p>
              </section>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full">
                <article :for={entry <- @uploads.image.entries} class="w-full p-4 bg-white rounded-lg shadow-sm">
                  <figure class="flex flex-col items-center">
                    <.live_img_preview entry={entry} class="mb-2 max-h-48 object-contain" />
                    <figcaption class="text-sm text-gray-600">{entry.client_name}</figcaption>
                  </figure>

                  <progress value={entry.progress} max="100" class="w-full h-2 bg-blue-100 rounded-lg mb-2">{entry.progress}%</progress>

                  <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-red-500 font-bold text-lg hover:text-red-700 transition duration-200" aria-label="cancel">&times;</button>

                  <p :for={err <- upload_errors(@uploads.image, entry)} class="mt-2 text-sm text-red-500">{error_to_string(err)}</p>
                </article>
              </div>

              <p :for={err <- upload_errors(@uploads.image)} class="mt-2 text-sm text-red-500">{error_to_string(err)}</p>
            </div>
          </div>

          <footer class="flex justify-end gap-3 pt-6">
            <.button navigate={return_path(@return_to, @cms_content_area)} variant="default">Cancel</.button>
            <.button type="submit" phx-disable-with="Saving..." variant="primary">Save Cms content area</.button>
          </footer>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    pages = Cms.list_cms_pages() |> Enum.map(&{&1.title, &1.id})
    cms_slots = Cms.list_cms_slots() |> Enum.map(&{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:pages, pages)
     |> assign(:cms_slots, cms_slots)
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:current_image, nil)
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .gif .webp .heic .heif .bmp .tiff), max_entries: 1, max_file_size: 20_000_000, external: &presign_upload/2)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_content_area = Cms.get_cms_content_area!(id)

    socket
    |> assign(:page_title, "Edit Cms content area")
    |> assign(:cms_content_area, cms_content_area)
    |> assign(:form, to_form(Cms.change_cms_content_area(cms_content_area)))
    |> assign(:current_image, Map.get(cms_content_area, :cms_image))
  end

  defp apply_action(socket, :new, _params) do
    cms_content_area = %CmsContentArea{}

    socket
    |> assign(:page_title, "New Cms content area")
    |> assign(:cms_content_area, cms_content_area)
    |> assign(:form, to_form(Cms.change_cms_content_area(cms_content_area)))
    |> assign(:current_image, nil)
  end

  @impl true
  def handle_event("validate", %{"cms_content_area" => cms_content_area_params}, socket) do
    {:noreply, assign(socket, form: to_form(Cms.change_cms_content_area(socket.assigns.cms_content_area, cms_content_area_params), action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"cms_content_area" => cms_content_area_params}, socket) do
    save_cms_content_area(socket, socket.assigns.live_action, cms_content_area_params)
  end

  defp save_cms_content_area(socket, :edit, cms_content_area_params) do
    updated_params = merge_file_params(socket, cms_content_area_params)

    case Cms.update_cms_content_area(socket.assigns.cms_content_area, updated_params) do
      {:ok, cms_content_area} ->
        {:noreply, socket |> put_flash(:info, "Cms content area updated successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_content_area))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_content_area(socket, :new, cms_content_area_params) do
    updated_params = merge_file_params(socket, cms_content_area_params)

    case Cms.create_cms_content_area(updated_params) do
      {:ok, cms_content_area} ->
        {:noreply, socket |> put_flash(:info, "Cms content area created successfully") |> push_navigate(to: return_path(socket.assigns.return_to, cms_content_area))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp merge_file_params(socket, cms_content_area_params) do
    uploaded_images =
      consume_uploaded_entries(socket, :image, fn meta, entry ->
        %{uploader: "S3", public_url: url, key: key} = meta
        {:ok, %{filename: entry.client_name, url: url, size: entry.client_size, content_type: entry.client_type, key: key}}
      end)

    case uploaded_images do
      [] ->
        cms_content_area_params

      [%{filename: filename, url: url, size: size, content_type: content_type} | _] ->
        # NOTE: you need Cms.create_cms_image/1 in the library context for this
        {:ok, image} = Cms.create_cms_image(%{"filename" => filename, "url" => url, "size" => size, "content_type" => content_type})
        Map.put(cms_content_area_params, "cms_image_id", image.id)
    end
  end

  defp presign_upload(entry, socket) do
    case S3Uploader.generate_presigned_url(entry.client_name, entry.client_type) do
      {:ok, upload_url, public_url, key} ->
        {:ok, %{uploader: "S3", url: upload_url, headers: %{"content-type" => entry.client_type, "x-amz-acl" => "public-read", "acl" => "public-read"}, fields: %{}, public_url: public_url, key: key}, socket}

      {:error, reason} ->
        {:error, reason, socket}
    end
  end

  defp return_path("index", _cms_content_area), do: DeadSimpleCms.path("/cms_content_areas")
  defp return_path("show", cms_content_area), do: DeadSimpleCms.path("/cms_content_areas/#{cms_content_area.id}")

  defp error_to_string({:too_large, %{max_size: max_size}}), do: "File is too large (maximum size is #{div(max_size, 1_000_000)} MB)"

  defp error_to_string({:not_accepted, %{accepted_types: types}}), do: "Only files of type: #{Enum.join(types, ", ")} are allowed"

  defp error_to_string(:external_client_failure), do: "Upload failed: client could not complete upload."

  defp error_to_string(:external_upload_failure), do: "Upload failed: server could not process upload."

  # Catch-all for anything weird or unexpected
  defp error_to_string(error), do: "Unexpected error: #{inspect(error)}"
end
