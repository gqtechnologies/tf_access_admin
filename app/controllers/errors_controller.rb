class ErrorsController < ApplicationController
    def not_found
      respond_to do |format|
        format.html do
          render inertia: "errors/not_found", status: :not_found
        end
        format.json { head :not_found }
        format.any { head :not_found }
      end
    end
end
