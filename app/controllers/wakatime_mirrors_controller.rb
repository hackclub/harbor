class WakatimeMirrorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_mirror, only: [ :update, :destroy ]

  def index
    @mirrors = current_user.wakatime_mirrors.active
    @new_mirror = WakatimeMirror.new
  end

  def create
    @mirror = current_user.wakatime_mirrors.build(mirror_params)

    if @mirror.save
      redirect_to wakatime_mirrors_path, notice: "Mirror was successfully created."
    else
      @mirrors = current_user.wakatime_mirrors.active
      @new_mirror = @mirror
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if @mirror.update(mirror_params)
      redirect_to wakatime_mirrors_path, notice: "Mirror was successfully updated."
    else
      @mirrors = current_user.wakatime_mirrors.active
      @new_mirror = WakatimeMirror.new
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "Destroying mirror #{@mirror.id}"
    result = @mirror.update(deleted_at: Time.current)
    Rails.logger.info "Update result: #{result}, Errors: #{@mirror.errors.full_messages}"

    if result
      redirect_to wakatime_mirrors_path, notice: "Mirror was successfully removed."
    else
      redirect_to wakatime_mirrors_path, alert: "Failed to remove mirror: #{@mirror.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_mirror
    @mirror = current_user.wakatime_mirrors.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Mirror not found with ID #{params[:id]}"
    redirect_to wakatime_mirrors_path, alert: "Mirror not found"
  end

  def mirror_params
    params.require(:wakatime_mirror).permit(:api_url, :api_key)
  end
end
