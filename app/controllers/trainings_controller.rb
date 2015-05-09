class TrainingsController < ApplicationController
  def index
    @trainings = Training.includes(:screencasts).where(:is_public => true).order(:display_date => :desc)
  end

  def show
    @training = Training.find_by_slug(params[:id])
    cat = Category.find(@training[:category_id])[:name]
    respond_to do |format|
      format.html {
        if @training.screencasts.size > 0 && @training[:skip]
          @screencast = @training.screencasts.first
          redirect_to training_screencast_path(@training[:slug], @screencast[:slug])
        end
      }
      format.json {
        render :json => @training.serializable_hash.merge(:category => cat)
      }
    end
  end
end
