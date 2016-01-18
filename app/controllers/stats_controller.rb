class StatsController < ApplicationController
  def show
    langs = Grp::Application::languages
    styles = Grp::Application::styles
    alignment = 30

    result = "Have #{styles.length} different styles\n"
    styles.each { |id, style|
      result += "ID: #{id}#{' ' * (40 - 4 - id.length)}Name: #{style.name}\n"
    }

    result += "\nHave #{langs.length} different languages\n"
    langs.each { |id, lang|
      result += "ID: #{id}#{' ' * (40 - 4 - id.length)}Name: #{lang}\n"
    }

    render plain: result
  end
end
