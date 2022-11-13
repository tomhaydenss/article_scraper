defmodule ArticleScraper do
  alias Publisher
  alias Html
  alias Pdf

  def scrap(issue_number) do
    scrap(issue_number, issue_number)
  end

  def scrap(begin_issue_number, end_issue_number) do
    begin_issue_number..end_issue_number
    |> Enum.map(&do_scrap/1)
  end

  defp do_scrap(issue_number) do
    issue_number
    |> Publisher.get_publishing()
    |> Publisher.get_article()
    |> Html.save()
  end

  def merge_content(filename) do
    {:ok, files} = File.ls("html")

    merged_content =
      files
      |> Enum.sort()
      |> Enum.map(&File.read!("html/#{&1}"))
      |> Enum.map(fn content ->
        {:ok, document} = Floki.parse_document(content)
        document
      end)
      |> Enum.map(&Floki.raw_html/1)
      |> Enum.join()

    full_content = """
    <html>
    <meta charset="utf-8"/>
    #{merged_content}
    </html>
    """

    html_file = "html/#{filename}.html"
    File.write!(html_file, full_content)
    Pdf.export(html_file)
  end
end
