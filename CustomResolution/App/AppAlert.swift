/// A message shown after an action, optionally offering to restart.
struct AppAlert {
    let title: String
    let message: String
    var offersRestart = false
}
