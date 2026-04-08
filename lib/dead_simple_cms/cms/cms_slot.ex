defmodule DeadSimpleCms.Cms.CmsSlot do
  @moduledoc """
  CmsSlot schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "cms_slots" do
    field :key, :string
    field :name, :string
    field :description, :string

    has_many :cms_content_areas, DeadSimpleCms.Cms.CmsContentArea

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cms_slot, attrs) do
    cms_slot
    |> cast(attrs, [:key, :name, :description])
    |> validate_required([:key, :name])
    |> unique_constraint(:key, name: :cms_slots_key_index)
  end
end
