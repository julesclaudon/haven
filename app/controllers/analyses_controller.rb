class AnalysesController < ApplicationController
  def index
    @analyses = Analysis.all
  end

  def show
    @analysis = Analysis.find(params[:id])
  end
end
