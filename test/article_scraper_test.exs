defmodule ArticleScraperTest do
  use ExUnit.Case
  doctest ArticleScraper

  test "greets the world" do
    assert ArticleScraper.hello() == :world
  end
end
