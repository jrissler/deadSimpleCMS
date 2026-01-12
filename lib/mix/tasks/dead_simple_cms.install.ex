defmodule Mix.Tasks.DeadSimpleCms.Install do
  use Mix.Task

  @shortdoc "Installs DeadSimpleCMS into the host app (copies migrations + optional component template)"

  @moduledoc """
  Installs DeadSimpleCMS into the host application.

  Copies:
    - EEx migration templates -> host priv/repo/migrations/<timestamp>_*.exs
    - optional CmsComponents module -> host lib/<app>_web/cms_components.ex (or a user-provided path)

  Usage:
    mix dead_simple_cms.install
    mix dead_simple_cms.install --no-components
    mix dead_simple_cms.install --components-path lib/my_app_web/cms_components.ex
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.config")
    Mix.Task.run("compile")

    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [no_components: :boolean, components_path: :string])
    no_components? = Keyword.get(opts, :no_components, false)
    components_path = Keyword.get(opts, :components_path, default_components_path())

    assigns = %{
      app: Mix.Project.config()[:app],
      app_module: app_module(),
      app_web_module: web_module()
    }

    templates_root = Path.join([:code.priv_dir(:dead_simple_cms) |> to_string(), "templates", "dead_simple_cms.install"])
    migrations_src = Path.join([templates_root, "migrations"])
    migrations_dest = Path.join(["priv", "repo", "migrations"])

    unless File.dir?(migrations_src) do
      Mix.raise("DeadSimpleCMS templates not found at #{migrations_src}. Did you include priv/templates in the package?")
    end

    File.mkdir_p!(migrations_dest)

    migrate_files =
      migrations_src
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".exs.eex"))
      |> Enum.sort()

    Enum.each(migrate_files, fn filename ->
      src = Path.join(migrations_src, filename)
      rendered = EEx.eval_file(src, assigns: assigns)
      dest = Path.join(migrations_dest, "#{timestamp()}_#{migration_basename(filename)}.exs")

      if File.exists?(dest) do
        Mix.raise("Refusing to overwrite existing migration: #{dest}")
      end

      File.write!(dest, rendered)
      Mix.shell().info("created #{dest}")
      bump_timestamp!()
    end)

    unless no_components? do
      components_src = Path.join([templates_root, "web", "cms_components.ex.eex"])

      if File.exists?(components_src) do
        rendered = EEx.eval_file(components_src, assigns: assigns)
        File.mkdir_p!(Path.dirname(components_path))

        if File.exists?(components_path) do
          Mix.shell().info("skipped #{components_path} (already exists)")
        else
          File.write!(components_path, rendered)
          Mix.shell().info("created #{components_path}")
        end
      else
        Mix.shell().info("skipped components (template missing at #{components_src})")
      end
    end

    Mix.shell().info("")
    Mix.shell().info("✅ DeadSimpleCMS install complete. Next:")
    Mix.shell().info("[ ] mix ecto.migrate")
    Mix.shell().info("[ ] Add DeadSimpleCmsWeb.Router.dead_simple_cms_admin_routes() to your router")
  end

  defp migration_basename(filename) do
    filename |> String.replace(~r/^\d+_/, "") |> String.replace_suffix(".exs.eex", "")
  end

  defp timestamp do
    DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  defp bump_timestamp! do
    Process.sleep(1100)
  end

  defp app_module do
    Mix.Project.config()[:app] |> to_string() |> Macro.camelize() |> String.to_atom()
  end

  defp web_module do
    Module.concat([app_module(), "Web"])
  end

  defp default_components_path do
    app = Mix.Project.config()[:app] |> to_string()
    Path.join(["lib", "#{app}_web", "components", "cms_components.ex"])
  end
end
