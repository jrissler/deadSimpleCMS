defmodule DeadSimpleCms.Uploaders.S3Uploader do
  @moduledoc """
  General purpose uploader for uploading directly to S3 using presigned URLs.
  """

  alias ExAws.S3

  def generate_presigned_url(original_filename, content_type) do
    DeadSimpleCms.ensure_ex_aws_configured()

    bucket = bucket()
    key = build_key(original_filename)
    params = %{"Content-Type" => content_type}
    config = ExAws.Config.new(:s3)

    case S3.presigned_url(config, :put, bucket, key, params: params, expires_in: 3600) do
      {:ok, upload_url} ->
        {:ok, upload_url, public_url(bucket, key), key}

      error ->
        error
    end
  end

  def public_url(bucket, key), do: "https://#{bucket}.s3.amazonaws.com/#{key}"

  def bucket do
    Application.get_env(:dead_simple_cms, :s3, []) |> Keyword.fetch!(:bucket)
  end

  @doc """
  Avoid collisions and keep keys safe.

  Example:
    "uploads/cms_images/<uuid>/<original_filename>"
  """
  def build_key(original_filename) do
    uuid = Ecto.UUID.generate()
    safe = original_filename |> String.replace(~r/[^a-zA-Z0-9\.\-_]/, "-")
    "uploads/cms_images/#{uuid}/#{safe}"
  end
end
