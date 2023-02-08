import ComposableArchitecture
import SwiftUI

struct InventoryFeature: Reducer {
  struct State {}
  enum Action {}

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
  }
}

struct InventoryView: View {
  let store: StoreOf<InventoryFeature>
  
  var body: some View {
    Text("Inventory")
  }
}
