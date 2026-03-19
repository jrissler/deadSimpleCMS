defmodule DeadSimpleCms.SpecialContent.CmsBio do
  @moduledoc """
  CmsBio schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "cms_bios" do
    field :name, :string
    field :job_title, :string
    field :tag_line, :string
    field :description, :string
    field :phone_number, :string
    field :email, :string
    field :facebook, :string
    field :instagram, :string
    field :tik_tok, :string
    field :linked_in, :string
    field :slug, :string
    field :visible, :boolean, default: true

    belongs_to :cms_image, DeadSimpleCms.Cms.CmsImage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cms_bio, attrs) do
    cms_bio
    |> cast(attrs, [:name, :job_title, :tag_line, :description, :phone_number, :email, :facebook, :instagram, :tik_tok, :linked_in, :slug, :visible, :cms_image_id])
    |> maybe_put_slug()
    |> validate_required([:name, :slug, :visible])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:cms_image_id)
  end

  defp maybe_put_slug(changeset) do
    slug = get_field(changeset, :slug)
    name = get_field(changeset, :name)

    cond do
      is_binary(slug) and String.trim(slug) != "" ->
        changeset

      is_binary(name) and String.trim(name) != "" ->
        put_change(changeset, :slug, slugify(name))

      true ->
        changeset
    end
  end

  defp slugify(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/\s+/u, "-")
    |> String.replace(~r/-+/u, "-")
  end
end
