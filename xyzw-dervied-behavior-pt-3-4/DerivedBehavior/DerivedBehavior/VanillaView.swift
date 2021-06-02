import Combine
import CombineSchedulers
import SwiftUI

class CounterViewModel: ObservableObject {
  @Published var alert: Alert?
  @Published var count = 0

  let fact: FactClient
  let mainQueue: AnySchedulerOf<DispatchQueue>

  private var cancellables: Set<AnyCancellable> = []

  init(
    fact: FactClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.fact = fact
    self.mainQueue = mainQueue
  }

  struct Alert: Equatable, Identifiable {
    var message: String
    var title: String

    var id: String {
      self.title + self.message
    }
  }

  func decrementButtonTapped() {
    self.count -= 1
  }
  func incrementButtonTapped() {
    self.count += 1
  }
  func factButtonTapped() {
    self.fact.fetch(self.count)
      .receive(on: self.mainQueue.animation())
      .sink(
        receiveCompletion: { [weak self] completion in
          if case .failure = completion {
            self?.alert = .init(message: "Couldn't load fact", title: "Error")
          }
        },
        receiveValue: { fact in
          // ???
        }
      )
      .store(in: &self.cancellables)
  }
}

struct VanillaCounterView: View {
  @ObservedObject var viewModel: CounterViewModel

  var body: some View {
    VStack {
      HStack {
        Button("-") { self.viewModel.decrementButtonTapped() }
        Text("\(self.viewModel.count)")
        Button("+") { self.viewModel.incrementButtonTapped() }
      }

      Button("Fact") { self.viewModel.factButtonTapped() }
    }
    .alert(item: self.$viewModel.alert) { alert in
      Alert(
        title: Text(alert.title),
        message: Text(alert.message)
      )
    }
  }
}

class CounterRowViewModel: ObservableObject, Identifiable {
  @Published var counter: CounterViewModel
  let id: UUID
  
  init(counter: CounterViewModel, id: UUID) {
    self.counter = counter
    self.id = id
  }
  
  func removeButtonTapped() {
    
  }
}

struct VanillaCounterRowView: View {
  let viewModel: CounterRowViewModel
  
  var body: some View {
    HStack {
      VanillaCounterView(
        viewModel: self.viewModel.counter
      )
      
      Spacer()
      
      Button("Remove") {
        withAnimation {
          self.viewModel.removeButtonTapped()
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}


class FactPromptViewModel: ObservableObject {
  let count: Int
  @Published var fact: String
  @Published var isLoading = false

  let factClient: FactClient
  let mainQueue: AnySchedulerOf<DispatchQueue>

  private var cancellables: Set<AnyCancellable> = []

  init(
    count: Int,
    fact: String,
    factClient: FactClient,
    mainQueue: AnySchedulerOf<DispatchQueue>
  ) {
    self.count = count
    self.fact = fact
    self.factClient = factClient
    self.mainQueue = mainQueue
  }

  func dismissButtonTapped() {

  }
  func getAnotherFactButtonTapped() {
    self.isLoading = true

    self.factClient.fetch(self.count)
      .receive(on: self.mainQueue.animation())
      .sink(
        receiveCompletion: { [weak self] _ in
          self?.isLoading = false
        },
        receiveValue: { [weak self] fact in
          self?.fact = fact
        }
      )
      .store(in: &self.cancellables)
  }
}

struct VanillaFactPrompt: View {
  @ObservedObject var viewModel: FactPromptViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "info.circle.fill")
          Text("Fact")
        }
        .font(.title3.bold())

        if self.viewModel.isLoading {
          ProgressView()
        } else {
          Text(self.viewModel.fact)
        }
      }

      HStack(spacing: 12) {
        Button("Get another fact") {
          self.viewModel.getAnotherFactButtonTapped()
        }

        Button("Dismiss") {
          self.viewModel.dismissButtonTapped()
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.1), radius: 20)
    .padding()
  }
}

class AppViewModel: ObservableObject {
  @Published var counters: [CounterRowViewModel] = []
  @Published var factPrompt: FactPromptViewModel?
  
  let fact: FactClient
  let mainQueue: AnySchedulerOf<DispatchQueue>
  let uuid: () -> UUID
  
  init(
    fact: FactClient,
    mainQueue: AnySchedulerOf<DispatchQueue>,
    uuid: @escaping () -> UUID
  ) {
    self.fact = fact
    self.mainQueue = mainQueue
    self.uuid = uuid
  }
  
  func addButtonTapped() {
    self.counters.append(
      .init(
        counter: CounterViewModel(
          fact: self.fact,
          mainQueue: self.mainQueue
        ),
        id: self.uuid()
      )
    )
  }
}

struct VanillaAppView: View {
  @ObservedObject var viewModel: AppViewModel
  
  var body: some View {
    ZStack(alignment: .bottom) {
      List {
        ForEach(self.viewModel.counters) { counterRow in
          VanillaCounterRowView(viewModel: counterRow)
        }
      }
      .navigationTitle("Counters")
      .navigationBarItems(
        trailing: Button("Add") {
          withAnimation {
            self.viewModel.addButtonTapped()
          }
        }
      )
      
      if let factPrompt = self.viewModel.factPrompt {
        VanillaFactPrompt(viewModel: factPrompt)
      }
    }
  }
}


struct Vanilla_Previews: PreviewProvider {
  static var previews: some View {
//    VanillaCounterView(
//      viewModel: .init(
//        fact: .live,
//        mainQueue: .main
//      )
//    )
    
    NavigationView {
      VanillaAppView(
        viewModel: .init(
          fact: .live,
          mainQueue: .main,
          uuid: UUID.init
        )
      )
    }
  }
}