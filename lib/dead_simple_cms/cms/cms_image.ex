defmodule DeadSimpleCms.Cms.CmsImage do
  @moduledoc """
  CmsImage schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cms_images" do
    field :filename, :string
    field :url, :string
    field :alt, :string
    field :caption, :string
    # currently not used
    field :width, :integer
    # currently not used
    field :height, :integer
    field :size, :integer
    field :content_type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:filename, :url, :alt, :caption, :width, :height, :size, :content_type])
    |> validate_required([:filename, :url])
    |> validate_length(:filename, min: 1, max: 255)
    |> validate_length(:alt, max: 255)
    |> validate_length(:caption, max: 255)
  end
end
