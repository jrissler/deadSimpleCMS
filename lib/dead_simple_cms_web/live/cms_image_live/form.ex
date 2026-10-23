defmodule DeadSimpleCmsWeb.CmsImageLive.Form do
  @moduledoc "Add an image or edit one: upload or replace the file, describe it, and delete it."
  use DeadSimpleCmsWeb, :live_view

  import DeadSimpleCmsWeb.CmsImageLive.Show, only: [usage_items: 1, usage_summary: 1, delete_confirmation: 2, delete_image: 1, file_type: 1, human_size: 1]

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCmsWeb.ImageUploads

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title="Images" description="Upload a photo once and reuse it in sections, bios and page share images.">
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_images")}>
          <.icon name="hero-arrow-left" class="size-4" /> All images
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="max-w-4xl mx-auto sm:px-6 lg:px-8">
        <div class="px-4 sm:px-0">
          <section aria-labelledby="cms-image-form-heading">
            <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
              <.form for={@form} id="cms_image-form" phx-change="validate" phx-submit="save" class="space-y-6 p-6 sm:p-8">
                <div>
                  <h2 id="cms-image-form-heading" class="text-base font-semibold tracking-tight text-gray-900">Image file</h2>
                  <p class="mt-1 text-sm text-gray-600">
                    {if @cms_image.id, do: "Upload a new file to replace this image everywhere it's used.", else: "Upload an image, or enter the details of an image that's already hosted below."}
                  </p>

                  <div :if={@cms_image.url} class="mt-4 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                    <div class="flex items-start gap-4">
                      <img src={@cms_image.url} alt={@cms_image.alt || ""} class="h-28 w-28 rounded-lg object-cover ring-1 ring-gray-300" />
                      <div class="flex-1 space-y-1">
                        <p class="text-sm text-gray-700"><span class="font-semibold text-gray-900">File name:</span> {@cms_image.filename}</p>
                        <p :if={file_type(@cms_image.content_type)} class="text-sm text-gray-700">
                          <span class="font-semibold text-gray-900">File type:</span> {file_type(@cms_image.content_type)}
                        </p>
                        <p :if={human_size(@cms_image.size)} class="text-sm text-gray-700"><span class="font-semibold text-gray-900">File size:</span> {human_size(@cms_image.size)}</p>
                      </div>
                    </div>
                  </div>

                  <div class="mt-6 flex flex-col items-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 p-6">
                    <div class="mb-4 flex w-full items-center justify-center">
                      <label for={@uploads.image.ref} class="inline-flex cursor-pointer items-center gap-2 rounded-md bg-white px-4 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus-within:outline focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-indigo-600">
                        <.icon name="hero-arrow-up-tray" class="h-5 w-5 text-gray-500" /> {if @cms_image.id, do: "Choose a new image", else: "Choose image"}
                      </label>

                      <.live_file_input upload={@uploads.image} class="sr-only" />
                    </div>

                    <section class="phx-drop-target mb-2 flex h-44 w-full flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-100 p-4 transition duration-200 hover:bg-gray-200" phx-drop-target={@uploads.image.ref}>
                      <p class="text-center text-gray-500">Drop your file here or click Choose image.</p>
                    </section>
                    <.hint id="cms_image-formats" class="mb-6 text-center">Use {ImageUploads.accepted_formats()}.</.hint>

                    <div class="grid w-full grid-cols-1 gap-4 sm:grid-cols-2">
                      <article :for={entry <- @uploads.image.entries} class="w-full rounded-lg bg-white p-4 shadow-sm">
                        <figure class="flex flex-col items-center">
                          <.live_img_preview entry={entry} class="mb-2 max-h-48 object-contain" />
                          <figcaption class="text-sm text-gray-600">{entry.client_name}</figcaption>
                        </figure>

                        <progress value={entry.progress} max="100" class="mb-2 h-2 w-full rounded-lg bg-blue-100">{entry.progress}%</progress>

                        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-sm font-semibold text-red-600 hover:text-red-500">Remove</button>

                        <p :for={err <- upload_errors(@uploads.image, entry)} class="mt-2 text-sm text-red-500">{ImageUploads.error_to_string(err)}</p>
                      </article>
                    </div>

                    <p :for={err <- upload_errors(@uploads.image)} class="mt-2 text-sm text-red-500">{ImageUploads.error_to_string(err)}</p>
                  </div>
                </div>

                <div class="grid grid-cols-1 gap-6 border-t border-zinc-200 pt-6">
                  <div>
                    <.input field={@form[:alt]} type="text" label="Description (alt text)" placeholder="For example: Two people on the bow of a boat at sunset" />
                    <.hint>Describe the photo in one plain sentence. Screen readers read it aloud, and search engines use it to understand the image.</.hint>
                  </div>
                  <div>
                    <.input field={@form[:caption]} type="text" label="Caption" />
                    <.hint>Optional. Shown with the image where your site uses captions. Put "Placeholder" in the caption to flag an image you still need to replace.</.hint>
                  </div>
                </div>

                <details id="cms_image-manual-details" class="border-t border-zinc-200 pt-6" open={!@cms_image.id and @form.errors != [] and @uploads.image.entries == []}>
                  <summary class="cursor-pointer text-sm font-semibold text-gray-700">Enter image details manually</summary>
                  <p class="mt-2 text-sm text-gray-600">Only needed for an image that's already hosted somewhere. Uploading a file fills these in for you.</p>

                  <div class="mt-4 grid grid-cols-1 gap-6">
                    <.input field={@form[:url]} type="text" label="Image URL" placeholder="https://..." />
                    <.input field={@form[:filename]} type="text" label="File name" placeholder="sunset.jpg" />
                    <.input field={@form[:content_type]} type="text" label="File type" placeholder="image/jpeg" />
                    <.input field={@form[:size]} type="text" label="File size (bytes)" />
                  </div>
                </details>

                <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                  <button
                    :if={@live_action == :edit}
                    type="button"
                    id="delete-cms-image"
                    phx-click="delete"
                    data-confirm={delete_confirmation(@cms_image, @usage_items)}
                    class="text-left text-sm font-semibold text-red-600 hover:text-red-500"
                  >
                    Delete image <span class="font-normal text-zinc-500">· {usage_summary(@usage_items)}</span>
                  </button>
                  <span :if={@live_action == :new}></span>
                  <div class="flex flex-col-reverse gap-3 sm:flex-row">
                    <.button navigate={return_path(@return_to, @cms_image)}>Cancel</.button>
                    <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Add image", else: "Save image"}</.button>
                  </div>
                </div>
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
     |> ImageUploads.allow_image_upload(:image)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    cms_image = Cms.get_cms_image!(id)

    socket
    |> assign(:page_title, "Edit image")
    |> assign(:cms_image, cms_image)
    |> assign(:usage_items, usage_items(Cms.image_usage(cms_image)))
    |> assign(:form, to_form(Cms.change_cms_image(cms_image)))
  end

  defp apply_action(socket, :new, _params) do
    cms_image = %CmsImage{}

    socket
    |> assign(:page_title, "Add image")
    |> assign(:cms_image, cms_image)
    |> assign(:usage_items, [])
    |> assign(:form, to_form(Cms.change_cms_image(cms_image)))
  end

  @impl true
  def handle_event("validate", %{"cms_image" => cms_image_params}, socket) do
    params = with_pending_upload(socket, cms_image_params)
    {:noreply, assign(socket, form: to_form(Cms.change_cms_image(socket.assigns.cms_image, params), action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("save", %{"cms_image" => cms_image_params}, socket) do
    save_cms_image(socket, socket.assigns.live_action, merge_upload_params(socket, cms_image_params))
  end

  def handle_event("delete", _params, socket) do
    case delete_image(socket.assigns.cms_image) do
      {:ok, message} -> {:noreply, socket |> put_flash(:info, message) |> push_navigate(to: DeadSimpleCms.path("/cms_images"))}
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  defp save_cms_image(socket, :edit, cms_image_params) do
    case Cms.update_cms_image(socket.assigns.cms_image, cms_image_params) do
      {:ok, cms_image} ->
        {:noreply, socket |> put_flash(:info, "Image saved") |> push_navigate(to: return_path(socket.assigns.return_to, cms_image))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_image(socket, :new, cms_image_params) do
    case Cms.create_cms_image(cms_image_params) do
      {:ok, cms_image} ->
        {:noreply, socket |> put_flash(:info, "Image added") |> push_navigate(to: return_path(socket.assigns.return_to, cms_image))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # While a file is waiting to upload, validate as if its details were already filled in,
  # so the form doesn't show "can't be blank" for fields the upload will set.
  defp with_pending_upload(socket, params) do
    case socket.assigns.uploads.image.entries do
      [entry | _] -> Map.merge(params, %{"url" => "pending upload", "filename" => entry.client_name, "content_type" => entry.client_type, "size" => entry.client_size})
      [] -> params
    end
  end

  # An uploaded file replaces the image's url, filename, type and size.
  defp merge_upload_params(socket, params) do
    case ImageUploads.consume_image_attrs(socket, :image) do
      nil -> params
      attrs -> Map.merge(params, attrs)
    end
  end

  defp return_path("index", _cms_image), do: DeadSimpleCms.path("/cms_images")
  defp return_path("show", %CmsImage{id: nil}), do: DeadSimpleCms.path("/cms_images")
  defp return_path("show", cms_image), do: DeadSimpleCms.path("/cms_images/#{cms_image.id}")
end
