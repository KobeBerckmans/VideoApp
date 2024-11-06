import SwiftUI

// Wrap the UIViewController for SwiftUI
struct VideoEditorViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoEditorViewController {
        return VideoEditorViewController()
    }
    
    func updateUIViewController(_ uiViewController: VideoEditorViewController, context: Context) {}
}

// ContentView
struct ContentView: View {
    @State private var showVideoEditor = false // State variable for navigation

    var body: some View {
        VStack {
            
            
            Button(action: {
                showVideoEditor.toggle() // Toggle the state variable
            }) {
                Text("Go to Video Editor")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
        .fullScreenCover(isPresented: $showVideoEditor) { 
            VideoEditorViewControllerWrapper()
        }
    }
}

#Preview {
    ContentView()
}
