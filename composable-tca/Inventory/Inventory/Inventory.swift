import ComposableArchitecture
import SwiftUI

struct InventoryFeature: Reducer {
  struct State: Equatable {
    var addItem: ItemFormFeature.State?
    var alert: AlertState<Action.Alert>?
    //var confirmationDialog: ConfirmationDialogState<Action.Dialog>?
    var duplicateItem: ItemFormFeature.State?
    var items: IdentifiedArrayOf<Item> = []
  }
  enum Action: Equatable {
    case addButtonTapped
    case addItem(PresentationAction<ItemFormFeature.Action>)
    case alert(PresentationAction<Alert>)
    case cancelAddItemButtonTapped
    case cancelDuplicateItemButtonTapped
    case confirmAddItemButtonTapped
    case confirmDuplicateItemButtonTapped
    //case confirmationDialog(PresentationAction<Dialog>)
    case deleteButtonTapped(id: Item.ID)
    //case dismissAddItem
    case duplicateButtonTapped(id: Item.ID)
    case duplicateItem(PresentationAction<ItemFormFeature.Action>)

    enum Alert: Equatable {
      case confirmDeletion(id: Item.ID)
    }
    enum Dialog: Equatable {
      case confirmDuplication(id: Item.ID)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.addItem = ItemFormFeature.State(
          item: Item(name: "", status: .inStock(quantity: 1))
        )
        return .none

//      case .addItem(.dismiss):
//        state.addItem = nil
//        return .none

      case .addItem:
        return .none
//      case let .addItem(action):
//        guard var itemFormState = state.addItem
//        else { return .none }
//        let itemFormEffects = ItemFormFeature().reduce(into: &itemFormState, action: action)
//        state.addItem = itemFormState
//        return itemFormEffects.map(Action.addItem)


      case let .alert(.presented(.confirmDeletion(id))):
        state.items.remove(id: id)
        return .none

//      case .alert(.dismiss):
//        state.alert = nil
//        return .none
        
      case .alert:
        return .none

      case .cancelAddItemButtonTapped:
        state.addItem = nil
        return .none

      case .cancelDuplicateItemButtonTapped:
        state.duplicateItem = nil
        return .none

      case .confirmAddItemButtonTapped:
        defer { state.addItem = nil }
        guard let item = state.addItem?.item
        else { return .none }
        state.items.append(item)
        return .none

      case .confirmDuplicateItemButtonTapped:
        defer { state.duplicateItem = nil }
        guard let item = state.duplicateItem?.item
        else { return .none }
        state.items.append(item)
        return .none

//      case let .confirmationDialog(.presented(.confirmDuplication(id: id))):
//        guard
//          let item = state.items[id: id],
//          let index = state.items.index(id: id)
//        else {
//          return .none
//        }
//        state.items.insert(item.duplicate(), at: index)
//        return .none
//
//      case .confirmationDialog(.dismiss):
//        return .none

      case let .deleteButtonTapped(id):
        guard let item = state.items[id: id]
        else { return .none }

        state.alert = .delete(item: item)
        return .none

      case let .duplicateButtonTapped(id):
        guard let item = state.items[id: id]
        else { return .none }

//        state.confirmationDialog = .duplicate(item: item)
        state.duplicateItem = ItemFormFeature.State(item: item.duplicate())
        return .none

      case .duplicateItem:
        return .none
      }
    }
//    .ifLet(\.alert, action: /Action.alert)
//    .ifLet(\.confirmationDialog, action: /Action.confirmationDialog)
//    .ifLet(\.addItem, action: /Action.addItem) {
//      ItemFormFeature()
//    }
    ifLet(\.duplicateItem, action: /Action.duplicateItem) {
      ItemFormFeature()
    }
//    let _ = \Item.status.isInStock
//    let _ = (\Item.status).appending(path: \Item.Status.isInStock)
  }
}

extension AlertState where Action == InventoryFeature.Action.Alert {
  static func delete(item: Item) -> Self {
    AlertState {
      TextState(#"Delete "\#(item.name)""#)
    } actions: {
      ButtonState(role: .destructive, action: .send(.confirmDeletion(id: item.id), animation: .default)) {
        TextState("Delete")
      }
    } message: {
      TextState("Are you sure you want to delete this item?")
    }
  }
}

extension ConfirmationDialogState where Action == InventoryFeature.Action.Dialog {
  static func duplicate(item: Item) -> Self {
    ConfirmationDialogState {
      TextState(#"Duplicate "\#(item.name)""#)
    } actions: {
      ButtonState(action: .send(.confirmDuplication(id: item.id), animation: .default)) {
        TextState("Duplicate")
      }
    } message: {
      TextState("Are you sure you want to duplicate this item?")
    }
  }
}

struct InventoryView: View {
  let store: StoreOf<InventoryFeature>

  struct ViewState: Equatable {
    let addItemID: Item.ID?
    let items: IdentifiedArrayOf<Item>

    init(state: InventoryFeature.State) {
      self.addItemID = state.addItem?.item.id
      self.items = state.items
    }
  }
  
  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { (viewStore: ViewStore<ViewState, InventoryFeature.Action>) in
      List {
        ForEach(viewStore.items) { item in
          HStack {
            VStack(alignment: .leading) {
              Text(item.name)

              switch item.status {
              case let .inStock(quantity):
                Text("In stock: \(quantity)")
              case let .outOfStock(isOnBackOrder):
                Text("Out of stock" + (isOnBackOrder ? ": on back order" : ""))
              }
            }

            Spacer()

            if let color = item.color {
              Rectangle()
                .frame(width: 30, height: 30)
                .foregroundColor(color.swiftUIColor)
                .border(Color.black, width: 1)
            }

            Button {
              viewStore.send(.duplicateButtonTapped(id: item.id))
            } label: {
              Image(systemName: "doc.on.doc.fill")
            }
            .padding(.leading)

            Button {
              viewStore.send(.deleteButtonTapped(id: item.id))
            } label: {
              Image(systemName: "trash.fill")
            }
            .padding(.leading)
          }
          .buttonStyle(.plain)
          .foregroundColor(item.status.isInStock ? nil : Color.gray)
        }
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Add") {
            viewStore.send(.addButtonTapped)
          }
        }
      }
      .alert(
        store: self.store.scope(state: \.alert, action: InventoryFeature.Action.alert)
      )
//      .confirmationDialog(
//        store: self.store.scope(state: \.confirmationDialog, action: InventoryFeature.Action.confirmationDialog)
//      )
      .sheet(
        store: self.store.scope(state: \.addItem, action: InventoryFeature.Action.addItem)
      ) { store in
        NavigationStack {
          ItemFormView(store: store)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  viewStore.send(.cancelAddItemButtonTapped)
                }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Add") {
                  viewStore.send(.confirmAddItemButtonTapped)
                }
              }
            }
            .navigationTitle("New item")
        }
      }
      .popover(
        store: self.store.scope(
          state: \.duplicateItem,
          action: InventoryFeature.Action.duplicateItem
        )
      ) { store in
        NavigationStack {
          ItemFormView(store: store)
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                  viewStore.send(.cancelDuplicateItemButtonTapped)
                }
              }
              ToolbarItem(placement: .primaryAction) {
                Button("Duplicate") {
                  viewStore.send(.confirmDuplicateItemButtonTapped)
                }
              }
            }
            .navigationTitle("Duplicate item")
        }
      }
    }
  }
}

struct Inventory_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      InventoryView(
        store: Store(
          initialState: InventoryFeature.State(
            items: [
              .headphones,
              .mouse,
              .keyboard,
              .monitor,
            ]
          ),
          reducer: InventoryFeature()
        )
      )
    }
  }
}
