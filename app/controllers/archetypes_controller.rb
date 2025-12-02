class ArchetypesController < ApplicationController
  def index
    @archetypes = Archetype.all
  end

  def show
    @archetype = Archetype.find(params[:id])
  end
end
