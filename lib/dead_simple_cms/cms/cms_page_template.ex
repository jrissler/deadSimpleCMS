defmodule DeadSimpleCms.Cms.CmsPageTemplate do
  @moduledoc """
  CmsPage schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cms_page_templates" do
    field :key, :string
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)

    has_many :cms_pages, DeadSimpleCms.Cms.CmsPage
    has_many :cms_content_areas, DeadSimpleCms.Cms.CmsContentArea
  end

  @doc false
  def changeset(cms_page_template, attrs) do
    cms_page_template
    |> cast(attrs, [:key, :name, :description])
    |> validate_required([:key, :name])
    |> unique_constraint(:key)
  end
end
