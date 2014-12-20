import spray.routing.SimpleRoutingApp
import akka.actor._


object Main extends App with SimpleRoutingApp {
  implicit val system = ActorSystem("chef-supervisord-fatjar-example")
  val port = 8000

  startServer(interface = "0.0.0.0", port = port) {
    path("") {
      complete {
        "Hello, World"
      }
    }
  }
}
