import spray.routing.SimpleRoutingApp
import akka.actor._
import util.Properties

object Main extends App with SimpleRoutingApp {
  implicit val system = ActorSystem("chef-supervisord-fatjar-example")
  val port = 8000

  startServer(interface = "0.0.0.0", port = Properties.envOrElse("PORT", "8000").toInt) {
    path("") {
      complete {
        Properties.envOrElse("GREETING", "Hello, World")
      }
    }
  }
}
