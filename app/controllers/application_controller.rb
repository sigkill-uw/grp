class ApplicationController < ActionController::Base
  rescue_from ActionController::RoutingError, :with => :not_found
  rescue_from ActiveRecord::RecordNotFound, :with => :not_found

  def not_found
    render template: "errors/not_found", status: 404
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
end
