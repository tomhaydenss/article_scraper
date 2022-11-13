defmodule Publisher do
  use HTTPoison.Base

  def get_publishing(issue_number) do
    url = "impressos/online/edicao/bs/#{issue_number}/"
    {:ok, document} = get!(url, headers()).body

    nrh_article =
      document
      |> Floki.find(".ui .big .content")
      |> Enum.map(&parse_article_properties/1)
      |> Enum.filter(&nrh_article?/1)

    case nrh_article do
      [article] -> article
      _ -> nil
    end
  end

  defp parse_article_properties({_, _, [header, properties]}) do
    {_, _, [section]} = header
    {_, _, list} = properties

    subsections = Enum.map(list, &parse_subsection/1)

    %{
      section: section,
      subsections: subsections
    }
  end

  defp parse_subsection(subsection) do
    {_,
     [
       {"href", link},
       _
     ], [title]} = subsection

    %{
      title: title,
      link: link
    }
  end

  defp nrh_article?(%{section: section}) do
    section
    |> String.split()
    |> Enum.map(fn word -> word |> String.graphemes() |> hd() end)
    |> Enum.join()
    |> Kernel.in(["CNRH", "NRH"])
  end

  def get_article(nil), do: nil

  def get_article(%{
        section: _,
        subsections: [
          %{link: url, title: title}
        ]
      }) do
    {:ok, document} = get!(url, headers()).body

    title = format_title(title)
    subtitle = parse_subtitle(document)
    image = parse_image(document)
    content = parse_content(document)

    issue_number = parse_issue_number(document)

    {issue_number,
     """
      #{title}
      #{subtitle}
      #{image}
      #{content}
     """}
  end

  defp parse_issue_number(document) do
    text =
      document
      |> Floki.find("div[class='ui label']")
      |> Floki.text()

    %{"issue_number" => issue_number} =
      Regex.named_captures(~r/Edição (?<issue_number>.\d+),/, text)

    issue_number
  end

  defp format_title(title), do: "<h1>#{title}</h1>"

  defp parse_subtitle(document) do
    document
    |> Floki.find(".ui .header .content .sub")
    |> Floki.text()
    |> then(&"<h2>#{&1}</h2>")
  end

  def parse_image(document) do
    document
    |> Floki.find("img[class~='impressos-online-foto']")
    |> Floki.find("img[data-modalid]")
    |> Floki.raw_html()
  end

  def parse_content(document) do
    [{_, _, innerContent}] = Floki.find(document, "div#conteudo")

    innerContent
    |> Floki.raw_html()
    |> String.split("<p><p>O personagem")
    |> hd()
    |> String.replace(~r/<sup>[[:digit:]]<\/sup>/, "")
  end

  def process_request_url(url), do: base_url() <> url

  def process_response_body(body), do: Floki.parse_document(body)

  defp base_url do
    System.get_env("BASE_URL")
  end

  defp session_id do
    System.get_env("SESSION_ID")
  end

  defp headers do
    [Cookie: "sessionid=#{session_id()}"]
  end
end
