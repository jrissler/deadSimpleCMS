defmodule Mix.Tasks.DeadSimpleCms.Install do
  use Mix.Task

  @shortdoc "Installs DeadSimpleCMS into the host app (copies migrations + required support files)"

  @moduledoc """
  Installs DeadSimpleCMS into the host application.

  Copies:
    - EEx migration templates -> host priv/repo/migrations/<timestamp>_*.exs
    - required CmsComponents module -> host lib/<app>_web/components/cms_components.ex (or a user-provided path)
    - required assets/js/uploaders.js

  Re-running the installer:
    - skips migrations already installed (matched by basename, ignoring timestamp)
    - skips uploaders.js if it already exists
    - skips cms_components.ex if it already exists

  Usage:
    mix dead_simple_cms.install
    mix dead_simple_cms.install --components-path lib/my_app_web/components/cms_components.ex
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config")
    Mix.Task.run("compile")

    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [components_path: :string])
    components_path = Keyword.get(opts, :components_path, default_components_path())

    assigns = %{
      app: Mix.Project.config()[:app],
      app_module: app_module(),
      app_web_module: web_module()
    }

    templates_root = Path.join([:code.priv_dir(:dead_simple_cms) |> to_string(), "templates", "dead_simple_cms.install"])
    migrations_src = Path.join([templates_root, "migrations"])
    migrations_dest = Path.join(["priv", "repo", "migrations"])
    assets_uploader_src = Path.join([templates_root, "assets", "js", "uploaders.js"])
    assets_uploader_dest = Path.join(["assets", "js", "uploaders.js"])
    components_src = Path.join([templates_root, "web", "cms_components.ex.eex"])

    copy_optional_if_missing!(assets_uploader_src, assets_uploader_dest, assigns, "assets uploader")
    copy_migrations!(migrations_src, migrations_dest, assigns)
    copy_optional_if_missing!(components_src, components_path, assigns, "components")

    Mix.shell().info("")
    Mix.shell().info("✅ DeadSimpleCMS install complete. Next:")
    Mix.shell().info("[ ] mix ecto.migrate")
    Mix.shell().info("[ ] Add DeadSimpleCmsWeb.Router.dead_simple_cms_admin_routes() to your router")
    Mix.shell().info("[ ] Import ./uploaders and register uploaders in assets/js/app.js (LiveSocket opts)")
  end

  defp copy_optional_if_missing!(src, dest, assigns, label) do
    if File.exists?(src) do
      File.mkdir_p!(Path.dirname(dest))

      if File.exists?(dest) do
        Mix.shell().info("skipped #{dest} (already exists)")
      else
        rendered = EEx.eval_file(src, assigns: assigns)
        File.write!(dest, rendered)
        Mix.shell().info("created #{dest}")
      end
    else
      Mix.raise("Required DeadSimpleCMS #{label} template missing at #{src}")
    end
  end

  defp copy_migrations!(migrations_src, migrations_dest, assigns) do
    unless File.dir?(migrations_src) do
      Mix.raise("DeadSimpleCMS templates not found at #{migrations_src}. Did you include priv/templates in the package?")
    end

    File.mkdir_p!(migrations_dest)

    existing_migration_files =
      if File.dir?(migrations_dest) do
        File.ls!(migrations_dest)
      else
        []
      end

    migrate_files =
      migrations_src
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".exs.eex"))
      |> Enum.sort()

    Enum.each(migrate_files, fn filename ->
      basename = migration_basename(filename)

      if migration_already_installed?(existing_migration_files, basename) do
        Mix.shell().info("skipped #{basename}.exs (already installed)")
      else
        src = Path.join(migrations_src, filename)
        rendered = EEx.eval_file(src, assigns: assigns)
        dest = Path.join(migrations_dest, "#{timestamp()}_#{basename}.exs")

        File.write!(dest, rendered)
        Mix.shell().info("created #{dest}")
        bump_timestamp!()
      end
    end)
  end

  defp migration_already_installed?(existing_files, basename) do
    Enum.any?(existing_files, &String.ends_with?(&1, "_#{basename}.exs"))
  end

  defp migration_basename(filename) do
    filename
    |> String.replace(~r/^\d+_/, "")
    |> String.replace_suffix(".exs.eex", "")
  end

  defp timestamp do
    DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp bump_timestamp! do
    Process.sleep(1100)
  end

  defp app_module do
    Mix.Project.config()[:app]
    |> to_string()
    |> Macro.camelize()
    |> String.to_atom()
  end

  defp web_module do
    Module.concat([app_module(), "Web"])
  end

  defp default_components_path do
    app = Mix.Project.config()[:app] |> to_string()
    Path.join(["lib", "#{app}_web", "components", "cms_components.ex"])
  end
end
