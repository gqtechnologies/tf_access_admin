import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
import {root_path} from '../routes';
// alert(`JsRoutes installed.\nYour root path is ${root_path()}`)
