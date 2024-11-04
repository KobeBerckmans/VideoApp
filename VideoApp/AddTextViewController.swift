import UIKit

class AddTextViewController: UIViewController {

    var completion: ((String, Double) -> Void)?

    let textField = UITextField()
    let timeTextField = UITextField()
    let addButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = .white

        // Configure textField
        textField.placeholder = "Voer de tekst in"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)

        // Configure timeTextField
        timeTextField.placeholder = "Voer tijd in seconden in"
        timeTextField.borderStyle = .roundedRect
        timeTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeTextField)

        // Configure addButton
        addButton.setTitle("Add", for: .normal)
        addButton.backgroundColor = .blue
        addButton.addTarget(self, action: #selector(addText), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

        // Layout
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            textField.widthAnchor.constraint(equalToConstant: 300),

            timeTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeTextField.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            timeTextField.widthAnchor.constraint(equalToConstant: 300),

            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.topAnchor.constraint(equalTo: timeTextField.bottomAnchor, constant: 20)
        ])
    }

    @objc func addText() {
        guard let text = textField.text, !text.isEmpty,
              let timeText = timeTextField.text, let time = Double(timeText) else {
            print("Vul alle velden in.")
            return
        }

        completion?(text, time)
        dismiss(animated: true, completion: nil)
    }
}
