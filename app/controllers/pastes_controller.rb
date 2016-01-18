class PastesController < ApplicationController
  def index
    @pastes = Paste.order(created_at: :desc).all
  end

  def new
  end

  def create
    if(@paste = Paste.create(paste_params))
      redirect_to "/pastes/#{@paste.id}"
    else
      render plain: "Failed to create paste"
    end
  end

  def show
    @paste = Paste.find(params[:id].to_i)
    if(params[:format] == "raw")
      render text: @paste.text, content_type: "text/plain"
    else
      render
    end
  end

  def paste_params
    params.require(:paste).permit(:title, :language_id, :text)
  end
end
