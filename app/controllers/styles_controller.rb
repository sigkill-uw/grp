class StylesController < ApplicationController
  def serialize
    id = params[:id]

    if(params[:format] == "css" and Grp::Application::styles.key?(id))
      render text: Grp::Application::styles[id].serialize(), content_type: "text/css"
    else
      raise ActionController::RoutingError.new("Not Found")
    end
  end
end
