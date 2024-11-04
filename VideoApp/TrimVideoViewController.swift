import UIKit
import AVFoundation

class TrimVideoViewController: UIViewController {

    var videoURL: URL?
    var completion: ((Double, Double) -> Void)?

    private let startTimeInput = UITextField()
    private let endTimeInput = UITextField()
    private let trimButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white

        startTimeInput.borderStyle = .roundedRect
        startTimeInput.placeholder = "Enter start time in seconds"
        startTimeInput.keyboardType = .decimalPad
        startTimeInput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startTimeInput)

        endTimeInput.borderStyle = .roundedRect
        endTimeInput.placeholder = "Enter end time in seconds"
        endTimeInput.keyboardType = .decimalPad
        endTimeInput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(endTimeInput)

        trimButton.setTitle("Trim", for: .normal)
        trimButton.backgroundColor = .systemBlue
        trimButton.addTarget(self, action: #selector(trimVideo), for: .touchUpInside)
        trimButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trimButton)

        NSLayoutConstraint.activate([
            startTimeInput.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            startTimeInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startTimeInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            endTimeInput.topAnchor.constraint(equalTo: startTimeInput.bottomAnchor, constant: 20),
            endTimeInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endTimeInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            trimButton.topAnchor.constraint(equalTo: endTimeInput.bottomAnchor, constant: 20),
            trimButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func trimVideo() {
        guard let startTimeText = startTimeInput.text, let endTimeText = endTimeInput.text,
              let startTime = Double(startTimeText), let endTime = Double(endTimeText) else {
            // ToDo: Show error message if input is invalid
            return
        }

        // Call the completion handler to pass back the start and end time
        completion?(startTime, endTime)
        dismiss(animated: true, completion: nil)
    }
}
