class ErrorsController < ApplicationController
    def not_found
        render inertia: "errors/not_found"
    end
end
