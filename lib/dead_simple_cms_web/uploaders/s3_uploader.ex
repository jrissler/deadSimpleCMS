defmodule DeadSimpleCms.Uploaders.S3Uploader do
  @moduledoc """
  General purpose uploader for uploading directly to S3 using presigned URLs.
  """

  alias ExAws.S3

  def generate_presigned_url(original_filename, content_type) do
    bucket = bucket()
    key = build_key(original_filename)
    params = %{"Content-Type" => content_type}
    config = ex_aws_s3_config()

    case S3.presigned_url(config, :put, bucket, key, params: params, expires_in: 3600) do
      {:ok, upload_url} ->
        {:ok, upload_url, public_url(bucket, key), key}

      error ->
        error
    end
  end

  def public_url(bucket, key), do: "https://#{bucket}.s3.amazonaws.com/#{key}"

  def bucket do
    s3_config() |> Keyword.fetch!(:bucket)
  end

  def region do
    s3_config() |> Keyword.fetch!(:region)
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

  defp ex_aws_s3_config do
    s3 = s3_config()

    ExAws.Config.new(:s3)
    |> Map.put(:region, Keyword.fetch!(s3, :region))
    |> Map.put(:access_key_id, Keyword.fetch!(s3, :access_key_id))
    |> Map.put(:secret_access_key, Keyword.fetch!(s3, :secret_access_key))
  end

  defp s3_config do
    Application.get_env(:dead_simple_cms, :s3, [])
  end
end
