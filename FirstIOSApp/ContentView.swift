

import SwiftUI

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case decodingFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .decodingFailed: return "Decoding failed"
        case .networkError(let s): return s
        }
    }
}

class APIService {
    private var user: User?
     let urlString = "https://api.speechify.example/user/1"

    func fetchUser(userData: User?) async throws -> User {
        
         guard let url = URL(string: urlString + "deneme") else { throw APIError.invalidURL }
         let (data, response) = try await URLSession.shared.data(from: url)
         guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw APIError.networkError("Bad status") }
         return try JSONDecoder().decode(User.self, from: data)
        
        user = userData
        print("{ \"id\": \(userData?.id), \"name\": \(userData?.name) }")
        let json = "{ \"id\": \(userData?.id), \"name\": \(userData?.name) }"
        
        guard let userData = userData else { throw APIError.decodingFailed }
        //let data = try JSONEncoder().encode(userData)
        return try JSONDecoder().decode(User.self, from: data)
        
        guard let data = json.data(using: .utf8) else { throw APIError.decodingFailed }
        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    func fetchUserResult(completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                let user = try await fetchUser(userData: user)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService()

    func loadUser(userData: User?) async {
        isLoading = true
        errorMessage = nil
        do {
            var fetched = try await api.fetchUser(userData: userData)
            user = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func heavyBackgroundTask() {
        Task.detached(priority: .background) {
            let result = (0..<1_000_000).reduce(0, +)
            await MainActor.run {
                self.errorMessage = "Background finished: \(result)"
            }
        }
    }
}

// -------------------------
// SwiftUI Görünümleri — @State, @Binding, @ObservedObject, @StateObject
// -------------------------

struct ContentView: View {
    @StateObject private var vm = UserViewModel()
    @State private var counter = 0
    @State private var inputText: String = ""


    var body: some View {
    NavigationView {
    VStack(spacing: 20) {
    HStack(spacing: 16) {
    Text("Counter: \(counter)")
    Button("+1") { counter += 1 }
    }


    if let user = vm.user {
    Text("User: \(user.name)")
    .font(.headline)
    } else if vm.isLoading {
    ProgressView()
    } else {
    Text("No user loaded")
    .foregroundColor(.secondary)
    }


    if let err = vm.errorMessage {
    Text("Error: \(err)")
    .foregroundColor(.red)
    .multilineTextAlignment(.center)
    }


    VStack(spacing: 10) {
    TextField("Enter your name", text: $inputText)
    .textFieldStyle(RoundedBorderTextFieldStyle())
    .padding(.horizontal)


    Button("Submit") {
    print("User entered: \(inputText)")
        Task { await vm.loadUser(userData: User(id: 1, name: inputText)) }
    }
    .buttonStyle(.borderedProminent)
    }


    ToggleParentView(isOn: $vm.isLoading)
    ChildObservedView(vm: vm)


    HStack {
    Button("Load User (async)") {
        Task { await vm.loadUser(userData: User(id: 1, name: inputText)) }
    }
    Button("Load User (Result)") {
    vm.isLoading = true
        APIService().fetchUserResult { result in
            DispatchQueue.main.async {
            vm.isLoading = false
                switch result {
                case .success(let u): vm.user = u
                case .failure(let e): vm.errorMessage = e.localizedDescription
                }
            }
        }
    }
}


Button("Do heavy background task") {
vm.heavyBackgroundTask()
}


Spacer()
}
.padding()
.navigationTitle("Debug Test Example")
}
}
}

struct ToggleParentView: View {
    @Binding var isOn: Bool

    var body: some View {
        VStack {
            Toggle("Loading Mode (binding)", isOn: $isOn)
                .labelsHidden()
            Text(isOn ? "Loading active" : "Loading inactive")
        }
    }
}

// Child view demonstrating @ObservedObject (paylaşılan view model)
struct ChildObservedView: View {
    @ObservedObject var vm: UserViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Observed child view")
                .font(.subheadline)
            if let name = vm.user?.name {
                Text("Name: \(name)")
            } else {
                Text("No user in child view")
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).stroke())
    }
}


func synchronousExample() {
    func risky() throws -> String {
        if Bool.random() { return "OK" }
        throw APIError.networkError("Random fail")
    }

    do {
        let r = try risky()
        print("Result: \(r)")
    } catch {
        print("Caught: \(error.localizedDescription)")
    }

    // Result tipi
    func maybe() -> Result<Int, Error> {
        Bool.random() ? .success(42) : .failure(APIError.networkError("boom"))
    }

    switch maybe() {
    case .success(let value): print("Value: \(value)")
    case .failure(let e): print("Err: \(e)")
    }
}


struct ImageView: View {
    let imageUrl: String

    var body: some View {
        if let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Text("Invalid URL")
        }
    }
}
