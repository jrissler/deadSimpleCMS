defmodule DeadSimpleCmsWeb.ImageUploads do
  @moduledoc """
  Direct-to-S3 image uploads shared by the admin forms (pages, sections,
  images, bios): the upload settings, the presigned URL, turning a finished
  upload into a `cms_images` record, and readable error messages.
  """

  import Phoenix.LiveView, only: [allow_upload: 3, consume_uploaded_entries: 3]

  alias DeadSimpleCms.Cms
  alias DeadSimpleCms.Uploaders.S3Uploader

  # Formats every browser can show on the public site.
  @accept ~w(.jpg .jpeg .png .gif .webp .avif)
  @max_file_size 20_000_000

  @doc "Allows a one-image upload named `name` on the socket, unless it's already allowed."
  def allow_image_upload(socket, name) do
    if Map.has_key?(socket.assigns[:uploads] || %{}, name) do
      socket
    else
      allow_upload(socket, name, accept: @accept, max_entries: 1, max_file_size: @max_file_size, external: &presign_upload/2)
    end
  end

  @doc "The accepted formats, for help text: \"JPG, PNG, GIF, WEBP or AVIF\"."
  def accepted_formats do
    names = Enum.map(@accept -- [".jpeg"], &(&1 |> String.trim_leading(".") |> String.upcase()))
    Enum.join(Enum.drop(names, -1), ", ") <> " or " <> List.last(names)
  end

  @doc """
  Consumes a finished upload into the attributes of a `cms_images` record.
  Returns `nil` when nothing was uploaded.
  """
  def consume_image_attrs(socket, name) do
    socket
    |> consume_uploaded_entries(name, fn meta, entry ->
      {:ok, %{"filename" => entry.client_name, "url" => meta[:public_url] || meta["public_url"], "size" => entry.client_size, "content_type" => entry.client_type}}
    end)
    |> List.first()
  end

  @doc """
  Consumes a finished upload into a new `cms_images` record, with `alt` as its
  description. Returns `{:ok, image}`, `{:error, changeset}` or `:none`.
  """
  def consume_image(socket, name, alt \\ nil) do
    case consume_image_attrs(socket, name) do
      nil -> :none
      attrs -> Cms.create_cms_image(Map.put(attrs, "alt", alt))
    end
  end

  @doc false
  def presign_upload(entry, socket) do
    case S3Uploader.generate_presigned_url(entry.client_name, entry.client_type) do
      {:ok, upload_url, public_url, key} ->
        {:ok, %{uploader: "S3", url: upload_url, headers: upload_headers(entry.client_type), fields: %{}, public_url: public_url, key: key}, socket}

      {:error, reason} ->
        {:error, reason, socket}
    end
  end

  # Signed image URLs are for private buckets, so the object isn't made public-read.
  defp upload_headers(content_type) do
    case Application.get_env(:dead_simple_cms, :image_urls, :public) do
      :signed -> %{"content-type" => content_type}
      _public -> %{"content-type" => content_type, "x-amz-acl" => "public-read", "acl" => "public-read"}
    end
  end

  @doc "A readable message for an upload error."
  def error_to_string({:too_large, %{max_size: max_size}}), do: "That file is too large. The limit is #{div(max_size, 1_000_000)} MB."
  def error_to_string(:too_large), do: "That file is too large. The limit is #{div(@max_file_size, 1_000_000)} MB."
  def error_to_string({:not_accepted, _}), do: "That file type isn't supported. Use #{accepted_formats()}."
  def error_to_string(:not_accepted), do: "That file type isn't supported. Use #{accepted_formats()}."
  def error_to_string(:too_many_files), do: "Choose one image at a time."
  def error_to_string(:external_client_failure), do: "The upload didn't finish. Check your connection and try again."
  def error_to_string(:external_upload_failure), do: "The upload didn't finish. Try again."
  def error_to_string(error), do: "The upload didn't work (#{inspect(error)})."
end
