defmodule DeadSimpleCms.Uploaders.S3Uploader do
  @moduledoc """
  General purpose uploader for uploading directly to S3 using presigned URLs.
  """

  alias ExAws.S3

  @default_expires_in 3600

  def generate_presigned_url(original_filename, content_type) do
    DeadSimpleCms.ensure_ex_aws_configured()

    bucket = bucket()
    key = build_key(original_filename)
    params = %{"Content-Type" => content_type}
    config = ExAws.Config.new(:s3)

    case S3.presigned_url(config, :put, bucket, key, params: params, expires_in: @default_expires_in) do
      {:ok, upload_url} -> {:ok, upload_url, public_url(bucket, key), key}
      error -> error
    end
  end

  @doc """
  Generates a temporary signed URL for reading a private S3 object from its
  stored S3 URL.
  """
  def generate_presigned_download_url(url, opts \\ []) do
    with {:ok, key} <- key_from_url(url) do
      generate_presigned_download_url_for_key(key, opts)
    end
  end

  @doc """
  Generates a temporary signed URL for reading a private S3 object by key.
  """
  def generate_presigned_download_url_for_key(key, opts \\ []) do
    DeadSimpleCms.ensure_ex_aws_configured()

    config = ExAws.Config.new(:s3)
    expires_in = Keyword.get(opts, :expires_in, @default_expires_in)

    S3.presigned_url(config, :get, bucket(), key, expires_in: expires_in)
  end

  @doc """
  Returns the canonical S3 URL for an object.

  Despite the historical `public_url` name, this does not make the object
  public. Object access is controlled by the bucket policy and object ACLs.
  For private buckets, use `generate_presigned_download_url/2` when the object
  needs to be accessed.
  """
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
    safe = String.replace(original_filename, ~r/[^a-zA-Z0-9\.\-_]/, "-")
    "uploads/cms_images/#{uuid}/#{safe}"
  end

  defp key_from_url(url) when is_binary(url) do
    prefix = public_url(bucket(), "")

    if String.starts_with?(url, prefix) do
      {:ok, String.replace_prefix(url, prefix, "")}
    else
      {:error, :invalid_s3_url}
    end
  end

  defp key_from_url(_), do: {:error, :invalid_s3_url}
end
