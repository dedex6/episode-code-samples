import SwiftUI

@main
struct ObservationExplorationsApp: App {
  var body: some Scene {
    WindowGroup {
      CounterView(model: CounterModel())
//      CounterView_ObservableObject(model: CounterModel_ObservableObject())
    }
  }
}
