defmodule DeadSimpleCmsWeb.CmsBioLive.Form do
  @moduledoc "Create or edit a bio: photo, name and job title first, then About, Contact and Social."
  use DeadSimpleCmsWeb, :live_view

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.SpecialContent
  alias DeadSimpleCms.SpecialContent.CmsBio
  alias DeadSimpleCmsWeb.ImageUploads

  @impl true
  def render(assigns) do
    ~H"""
    <.content_header main_title={@page_title} sub_title={@live_action == :edit && @cms_bio.name} description="A person's profile: who they are, what they do and how to reach them.">
      <:action>
        <.button navigate={DeadSimpleCms.path("/cms_bios")}>
          <.icon name="hero-arrow-left" class="size-4" /> All bios
        </.button>
        <.button :if={@live_action == :edit} navigate={DeadSimpleCms.path("/cms_bios/#{@cms_bio.id}")}>
          <.icon name="hero-eye" class="size-4" /> View bio
        </.button>
      </:action>
    </.content_header>

    <main class="pt-2 pb-16 mt-0">
      <div class="mx-auto max-w-5xl space-y-10 px-4 sm:px-6 lg:px-8">
        <section aria-labelledby="bio-person-heading">
          <div class="overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
            <.form for={@form} id="cms_bio-form" phx-change="validate" phx-submit="save" class="space-y-8 p-6 sm:p-8">
              <div class="space-y-5">
                <h2 id="bio-person-heading" class="text-lg font-semibold tracking-tight text-gray-900">Person</h2>

                <div class="flex flex-col gap-6 sm:flex-row sm:items-start">
                  <div id="bio-photo" class="shrink-0 sm:w-48">
                    <span class="label mb-1">Photo</span>
                    <img :if={@current_image} src={Cms.image_url(@current_image)} alt={@current_image.alt || ""} class="h-40 w-40 rounded-xl object-cover ring-1 ring-gray-300" />
                    <div :if={!@current_image && @uploads.image.entries == []} class="grid h-40 w-40 place-items-center rounded-xl bg-zinc-100 text-zinc-400 ring-1 ring-zinc-200">
                      <.icon name="hero-user" class="size-12" />
                    </div>

                    <div :for={entry <- @uploads.image.entries} class="mt-2 space-y-2">
                      <.live_img_preview :if={!@current_image} entry={entry} class="h-40 w-40 rounded-xl object-cover ring-1 ring-gray-300" />
                      <div class="flex items-center gap-2">
                        <p class="min-w-0 flex-1 truncate text-xs text-gray-600">{if @current_image, do: "New photo: "}{entry.client_name}</p>
                        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-lg font-bold leading-none text-red-500 hover:text-red-700" aria-label="Cancel upload">&times;</button>
                      </div>
                      <progress value={entry.progress} max="100" class="h-2 w-full rounded-lg bg-blue-100">{entry.progress}%</progress>
                      <p :for={err <- upload_errors(@uploads.image, entry)} class="text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                    </div>

                    <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-2">
                      <label for={@uploads.image.ref} class="inline-flex cursor-pointer items-center gap-2 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                        <.icon name="hero-arrow-up-tray" class="size-4 text-gray-500" /> {if @current_image, do: "Replace photo", else: "Add photo"}
                      </label>
                      <button
                        :if={@current_image}
                        type="button"
                        id="remove-bio-photo"
                        phx-click="remove-photo"
                        data-confirm="Take the photo off this bio? The photo stays in your image library."
                        class="text-sm font-semibold text-red-600 hover:text-red-500"
                      >
                        Remove photo
                      </button>
                    </div>
                    <.live_file_input upload={@uploads.image} class="sr-only" />
                    <div class="phx-drop-target" phx-drop-target={@uploads.image.ref}>
                      <.hint>Or drop a file here. {ImageUploads.accepted_formats()}. A square photo works best. It's added when you save.</.hint>
                    </div>
                    <p :for={err <- upload_errors(@uploads.image)} class="mt-1 text-xs text-red-500">{ImageUploads.error_to_string(err)}</p>
                  </div>

                  <div class="min-w-0 flex-1 space-y-5">
                    <.input field={@form[:name]} type="text" label="Name" />
                    <div>
                      <.input field={@form[:job_title]} type="text" label="Job title" placeholder="Captain" />
                      <.hint>Optional. Shown under their name.</.hint>
                    </div>

                    <div :if={@current_image || @uploads.image.entries != []}>
                      <label for="bio-image-alt" class="label mb-1">Photo description</label>
                      <input type="text" id="bio-image-alt" name="image_alt" value={@image_alt} class="input w-full" placeholder="For example: James smiling at the helm of Empire" />
                      <.hint>Describes the photo for people using screen readers, and helps search engines. One plain sentence.</.hint>
                    </div>
                  </div>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <h2 class="text-lg font-semibold tracking-tight text-gray-900">About</h2>
                <div>
                  <.input field={@form[:tag_line]} type="text" label="Tag line" />
                  <.hint>Optional. One short line about them, like a motto.</.hint>
                </div>
                <div>
                  <.input field={@form[:description]} type="textarea" label="About them" rows="6" />
                  <.hint>Optional. A few sentences about who they are.</.hint>
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <div>
                  <h2 class="text-lg font-semibold tracking-tight text-gray-900">Contact</h2>
                  <p class="mt-1 text-sm text-gray-600">Optional. Anything left blank stays off the site.</p>
                </div>
                <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
                  <.input field={@form[:email]} type="email" label="Email" placeholder="name@example.com" autocomplete="off" />
                  <.input field={@form[:phone_number]} type="tel" label="Phone number" placeholder="(555) 123-4567" autocomplete="off" />
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <div>
                  <h2 class="text-lg font-semibold tracking-tight text-gray-900">Social</h2>
                  <p class="mt-1 text-sm text-gray-600">Optional. Paste the full web address of each profile, the one you see when you open it in a browser.</p>
                </div>
                <div class="grid grid-cols-1 gap-5 sm:grid-cols-2">
                  <.input field={@form[:facebook]} type="text" inputmode="url" label="Facebook" placeholder="https://facebook.com/yourname" />
                  <.input field={@form[:instagram]} type="text" inputmode="url" label="Instagram" placeholder="https://instagram.com/yourname" />
                  <.input field={@form[:tik_tok]} type="text" inputmode="url" label="TikTok" placeholder="https://tiktok.com/@yourname" />
                  <.input field={@form[:linked_in]} type="text" inputmode="url" label="LinkedIn" placeholder="https://linkedin.com/in/yourname" />
                </div>
              </div>

              <div class="space-y-5 border-t border-zinc-200 pt-8">
                <h2 class="text-lg font-semibold tracking-tight text-gray-900">On the site</h2>
                <div>
                  <.input field={@form[:slug]} type="text" label="Profile address" placeholder="jane-smith" />
                  <.hint>The end of this bio's web address, in lowercase words joined by dashes. {if @live_action == :new, do: "Filled in from the name if you leave it blank.", else: "Changing it breaks links people already have."}</.hint>
                </div>
                <div class="rounded-lg border border-zinc-200 bg-zinc-50 p-4">
                  <.input field={@form[:visible]} type="checkbox" label="Show this bio on the site" />
                  <.hint>Uncheck to hide it without deleting it.</.hint>
                </div>
              </div>

              <div class="flex flex-col-reverse gap-3 border-t border-zinc-200 pt-6 sm:flex-row sm:items-center sm:justify-between">
                <button :if={@live_action == :edit} type="button" id="delete-cms-bio" phx-click="delete" data-confirm={"Delete the bio for \"#{@cms_bio.name}\"? This can't be undone."} class="text-sm font-semibold text-red-600 hover:text-red-500">
                  Delete bio
                </button>
                <span :if={@live_action == :new}></span>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                  <.button navigate={return_path(@return_to, @cms_bio)}>Cancel</.button>
                  <.button type="submit" variant="primary" phx-disable-with="Saving...">{if @live_action == :new, do: "Create bio", else: "Save bio"}</.button>
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
     |> ImageUploads.allow_image_upload(:image)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit bio")
    |> assign_bio(SpecialContent.get_cms_bio!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New bio")
    |> assign_bio(%CmsBio{cms_image: nil})
  end

  defp assign_bio(socket, cms_bio) do
    socket
    |> assign(:cms_bio, cms_bio)
    |> assign(:form, to_form(SpecialContent.change_cms_bio(cms_bio)))
    |> assign(:current_image, cms_bio.cms_image)
    |> assign(:image_alt, cms_bio.cms_image && cms_bio.cms_image.alt)
  end

  @impl true
  def handle_event("validate", %{"cms_bio" => cms_bio_params} = params, socket) do
    changeset = SpecialContent.change_cms_bio(socket.assigns.cms_bio, cms_bio_params)
    {:noreply, socket |> assign(:form, to_form(changeset, action: :validate)) |> assign(:image_alt, Map.get(params, "image_alt", socket.assigns.image_alt))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("remove-photo", _params, socket) do
    case SpecialContent.update_cms_bio(socket.assigns.cms_bio, %{cms_image_id: nil}) do
      {:ok, cms_bio} ->
        # Keep whatever the editor has typed but not saved yet.
        changeset = SpecialContent.change_cms_bio(cms_bio, socket.assigns.form.params || %{})

        {:noreply,
         socket
         |> put_flash(:info, "Photo removed from the bio")
         |> assign(cms_bio: %{cms_bio | cms_image: nil}, current_image: nil, image_alt: nil, form: to_form(changeset))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "The photo couldn't be removed. Try again.")}
    end
  end

  def handle_event("delete", _params, socket) do
    cms_bio = socket.assigns.cms_bio

    case SpecialContent.delete_cms_bio(cms_bio) do
      {:ok, _} -> {:noreply, socket |> put_flash(:info, "Bio \"#{cms_bio.name}\" deleted") |> push_navigate(to: DeadSimpleCms.path("/cms_bios"))}
      {:error, _} -> {:noreply, put_flash(socket, :error, "The bio for \"#{cms_bio.name}\" couldn't be deleted. Try again.")}
    end
  end

  def handle_event("save", %{"cms_bio" => cms_bio_params} = params, socket) do
    alt = present(params["image_alt"])

    with {:ok, cms_bio_params} <- attach_upload(socket, cms_bio_params, alt),
         :ok <- update_image_alt(socket.assigns.current_image, cms_bio_params, alt) do
      save_cms_bio(socket, socket.assigns.live_action, cms_bio_params)
    else
      {:error, _image_changeset} -> {:noreply, put_flash(socket, :error, "The photo couldn't be saved. Try the upload again.")}
    end
  end

  defp save_cms_bio(socket, :edit, cms_bio_params) do
    case SpecialContent.update_cms_bio(socket.assigns.cms_bio, cms_bio_params) do
      {:ok, cms_bio} -> {:noreply, socket |> put_flash(:info, "Bio saved") |> push_navigate(to: return_path(socket.assigns.return_to, cms_bio))}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cms_bio(socket, :new, cms_bio_params) do
    case SpecialContent.create_cms_bio(cms_bio_params) do
      {:ok, cms_bio} -> {:noreply, socket |> put_flash(:info, "Bio created") |> push_navigate(to: return_path(socket.assigns.return_to, cms_bio))}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp attach_upload(socket, cms_bio_params, alt) do
    case ImageUploads.consume_image(socket, :image, alt) do
      :none -> {:ok, cms_bio_params}
      {:ok, image} -> {:ok, Map.put(cms_bio_params, "cms_image_id", image.id)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # The description typed for the bio's current photo is saved on that photo.
  defp update_image_alt(%{alt: current} = image, cms_bio_params, alt) when not is_map_key(cms_bio_params, "cms_image_id") and alt != current do
    case Cms.update_cms_image(image, %{alt: alt}) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp update_image_alt(_image, _cms_bio_params, _alt), do: :ok

  defp present(value) when is_binary(value), do: if(String.trim(value) == "", do: nil, else: String.trim(value))
  defp present(_value), do: nil

  defp return_path("show", %CmsBio{id: id}) when not is_nil(id), do: DeadSimpleCms.path("/cms_bios/#{id}")
  defp return_path(_return_to, _cms_bio), do: DeadSimpleCms.path("/cms_bios")
end
