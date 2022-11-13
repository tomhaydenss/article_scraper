defmodule Pdf do
  alias Porcelain.Result

  def export(nil), do: :no_content

  def export(html_file) do
    pdf_file = Path.basename(html_file, ".html") <> ".pdf"
    shell_params = ["--page-size", "A4", "-q"]
    executable = System.find_executable("wkhtmltopdf")
    arguments = List.flatten([shell_params, html_file, "pdf/#{pdf_file}"])

    %Result{out: _output, status: status, err: error} =
      Porcelain.exec(
        executable,
        arguments,
        in: "",
        out: :string,
        err: :string
      )

    case status do
      0 ->
        {:ok, pdf_file}

      _ ->
        {:error, error}
    end
  end
end
