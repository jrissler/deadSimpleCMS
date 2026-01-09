defmodule DeadSimpleCms.Cms do
  @moduledoc """
  The Cms context.
  """

  import Ecto.Query, warn: false

  alias DeadSimpleCms.Cms.CmsPage
  alias DeadSimpleCms.Cms.CmsImage
  alias DeadSimpleCms.Cms.CmsContentArea

  defp repo, do: DeadSimpleCms.repo!()

  @doc """
  Returns the list of cms_pages.

  ## Examples

      iex> list_cms_pages()
      [%CmsPage{}, ...]

  """
  def list_cms_pages do
    repo().all(CmsPage)
  end

  @doc """
  Gets a single cms_page.

  Raises `Ecto.NoResultsError` if the Cms page does not exist.

  ## Examples

      iex> get_cms_page!(123)
      %CmsPage{}

      iex> get_cms_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_page!(id), do: repo().get!(CmsPage, id)

  @doc """
  Creates a cms_page.

  ## Examples

      iex> create_cms_page(%{field: value})
      {:ok, %CmsPage{}}

      iex> create_cms_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_page(attrs) do
    %CmsPage{}
    |> CmsPage.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_page.

  ## Examples

      iex> update_cms_page(cms_page, %{field: new_value})
      {:ok, %CmsPage{}}

      iex> update_cms_page(cms_page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_page(%CmsPage{} = cms_page, attrs) do
    cms_page
    |> CmsPage.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_page.

  ## Examples

      iex> delete_cms_page(cms_page)
      {:ok, %CmsPage{}}

      iex> delete_cms_page(cms_page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_page(%CmsPage{} = cms_page) do
    repo().delete(cms_page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_page changes.

  ## Examples

      iex> change_cms_page(cms_page)
      %Ecto.Changeset{data: %CmsPage{}}

  """
  def change_cms_page(%CmsPage{} = cms_page, attrs \\ %{}) do
    CmsPage.changeset(cms_page, attrs)
  end

  @doc """
  Returns the list of cms_images.

  ## Examples

      iex> list_cms_images()
      [%CmsImage{}, ...]

  """
  def list_cms_images do
    repo().all(CmsImage)
  end

  @doc """
  Gets a single cms_image.

  Raises `Ecto.NoResultsError` if the Cms image does not exist.

  ## Examples

      iex> get_cms_image!(123)
      %CmsImage{}

      iex> get_cms_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_image!(id), do: repo().get!(CmsImage, id)

  @doc """
  Creates a cms_image.

  ## Examples

      iex> create_cms_image(%{field: value})
      {:ok, %CmsImage{}}

      iex> create_cms_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_image(attrs) do
    %CmsImage{}
    |> CmsImage.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_image.

  ## Examples

      iex> update_cms_image(cms_image, %{field: new_value})
      {:ok, %CmsImage{}}

      iex> update_cms_image(cms_image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_image(%CmsImage{} = cms_image, attrs) do
    cms_image
    |> CmsImage.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_image.

  ## Examples

      iex> delete_cms_image(cms_image)
      {:ok, %CmsImage{}}

      iex> delete_cms_image(cms_image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_image(%CmsImage{} = cms_image) do
    repo().delete(cms_image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_image changes.

  ## Examples

      iex> change_cms_image(cms_image)
      %Ecto.Changeset{data: %CmsImage{}}

  """
  def change_cms_image(%CmsImage{} = cms_image, attrs \\ %{}) do
    CmsImage.changeset(cms_image, attrs)
  end

  @doc """
  Returns the list of cms_content_areas.

  ## Examples

      iex> list_cms_content_areas()
      [%CmsContentArea{}, ...]

  """
  def list_cms_content_areas do
    repo().all(CmsContentArea)
  end

  @doc """
  Gets a single cms_content_area.

  Raises `Ecto.NoResultsError` if the Cms content area does not exist.

  ## Examples

      iex> get_cms_content_area!(123)
      %CmsContentArea{}

      iex> get_cms_content_area!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cms_content_area!(id), do: repo().get!(CmsContentArea, id)

  @doc """
  Creates a cms_content_area.

  ## Examples

      iex> create_cms_content_area(%{field: value})
      {:ok, %CmsContentArea{}}

      iex> create_cms_content_area(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cms_content_area(attrs) do
    %CmsContentArea{}
    |> CmsContentArea.changeset(attrs)
    |> repo().insert()
  end

  @doc """
  Updates a cms_content_area.

  ## Examples

      iex> update_cms_content_area(cms_content_area, %{field: new_value})
      {:ok, %CmsContentArea{}}

      iex> update_cms_content_area(cms_content_area, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cms_content_area(%CmsContentArea{} = cms_content_area, attrs) do
    cms_content_area
    |> CmsContentArea.changeset(attrs)
    |> repo().update()
  end

  @doc """
  Deletes a cms_content_area.

  ## Examples

      iex> delete_cms_content_area(cms_content_area)
      {:ok, %CmsContentArea{}}

      iex> delete_cms_content_area(cms_content_area)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cms_content_area(%CmsContentArea{} = cms_content_area) do
    repo().delete(cms_content_area)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cms_content_area changes.

  ## Examples

      iex> change_cms_content_area(cms_content_area)
      %Ecto.Changeset{data: %CmsContentArea{}}

  """
  def change_cms_content_area(%CmsContentArea{} = cms_content_area, attrs \\ %{}) do
    CmsContentArea.changeset(cms_content_area, attrs)
  end
end
