import UIKit
import AVFoundation
import Photos

class VideoEditorViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: URL?
    var filters = ["none", "CISepiaTone", "CIColorControls"] // Beschikbare filters
    var selectedFilter: String = "none" // Huidig geselecteerde filter
    var textInput: UITextField!
    var overlayText: String = "" // Text overlay
    var filterPicker: UIPickerView! // Typo was hier, moest UIPickerView zijn
    var trimSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 1
        return slider
    }()
    var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI() // UI opzetten
    }

    func setupUI() {
        view.backgroundColor = .white

        // Video Player View
        let videoPlayerView = UIView()
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoPlayerView)

        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.heightAnchor.constraint(equalToConstant: 300)
        ])

        // Knoppen voor de verschillende functies
        let importButton = createButton(title: "Import Video", action: #selector(importVideo))
        let applyFilterButton = createButton(title: "Apply Filter", action: #selector(applyFilter))
        let trimButton = createButton(title: "Trim Video", action: #selector(trimVideo))

        let addTextButton = createButton(title: "Add Text", action: #selector(addText))
        let exportButton = createButton(title: "Export Video", action: #selector(exportVideo))

        // Stack view voor knoppen
        stackView = UIStackView(arrangedSubviews: [importButton, applyFilterButton, trimButton, addTextButton, exportButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Picker voor filters
        filterPicker = UIPickerView() // Correcte naam is UIPickerView
        filterPicker.delegate = self
        filterPicker.dataSource = self
        filterPicker.translatesAutoresizingMaskIntoConstraints = false
        filterPicker.isHidden = true // Begin verborgen
        view.addSubview(filterPicker)

        NSLayoutConstraint.activate([
            filterPicker.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            filterPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Slider voor het trimmen van de video
        trimSlider.addTarget(self, action: #selector(trimSliderChanged(_:)), for: .valueChanged)
        trimSlider.translatesAutoresizingMaskIntoConstraints = false
        trimSlider.isHidden = false // Begin verborgen
        view.addSubview(trimSlider)

        NSLayoutConstraint.activate([
            trimSlider.topAnchor.constraint(equalTo: filterPicker.bottomAnchor, constant: 20),
            trimSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            trimSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Textfield voor het invoeren van overlay tekst
        textInput = UITextField(frame: CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 40))
        textInput.borderStyle = .roundedRect
        textInput.placeholder = "Enter text to overlay"
        textInput.translatesAutoresizingMaskIntoConstraints = false
        textInput.isHidden = true // Begin verborgen
        view.addSubview(textInput)

        NSLayoutConstraint.activate([
            textInput.topAnchor.constraint(equalTo: trimSlider.bottomAnchor, constant: 20),
            textInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc func importVideo() {
        // Laad de video vanuit de bundel
        videoURL = Bundle.main.url(forResource: "kobe_berckmans_", withExtension: "mp4")
        if let videoURL = videoURL {
            playVideo(url: videoURL) // Speel de video af
            filterPicker.isHidden = false // Toon de filter picker
            trimSlider.isHidden = false // Toon de trim slider
            textInput.isHidden = false // Toon de text input
        } else {
            print("Video niet gevonden")
        }
    }

    func playVideo(url: URL) {
        player = AVPlayer(url: url) // Maak een AVPlayer met de video URL
        playerLayer = AVPlayerLayer(player: player) // Maak een layer voor de video
        playerLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300) // Stel de grootte van de layer in
        playerLayer.videoGravity = .resizeAspect // Houd de aspect ratio van de video
        view.layer.addSublayer(playerLayer) // Voeg de layer toe aan de view
        player.play() // Begin met afspelen
    }

    @objc func applyFilter() {
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }
        print("Filter toepassen: \(selectedFilter)")

        let asset = AVAsset(url: videoURL) // Maak een AVAsset van de video
        let composition = AVMutableComposition() // Maak een mutable composition

        // Verkrijg de video en audio tracks van het asset
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) // Voeg een videotrack toe aan de composition
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) // Voeg een audiotrack toe aan de composition

        do {
            // Voeg de video- en audiotracks toe aan de composition
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)

            // Maak een video composition voor het toepassen van filters
            let videoComposition = AVMutableVideoComposition(asset: composition) { request in
                let source = request.sourceImage.clampedToExtent() // Krijg de bronafbeelding
                var outputImage: CIImage? // Afbeelding na filter

                // Pas het geselecteerde filter toe
                if self.selectedFilter == "none" {
                    outputImage = source
                } else if self.selectedFilter == "CISepiaTone" {
                    let filter = CIFilter(name: self.selectedFilter)!
                    filter.setValue(source, forKey: kCIInputImageKey)
                    filter.setValue(0.8, forKey: kCIInputIntensityKey)
                    outputImage = filter.outputImage
                } else if self.selectedFilter == "CIColorControls" {
                    let filter = CIFilter(name: self.selectedFilter)!
                    filter.setValue(source, forKey: kCIInputImageKey)
                    filter.setValue(1.5, forKey: kCIInputContrastKey)
                    filter.setValue(0.5, forKey: kCIInputBrightnessKey)
                    filter.setValue(0.0, forKey: kCIInputSaturationKey)
                    outputImage = filter.outputImage
                }

                request.finish(with: outputImage ?? source, context: nil) // Geef het resultaat terug
            }

            let playerItem = AVPlayerItem(asset: composition) // Maak een AVPlayerItem
            playerItem.videoComposition = videoComposition // Stel de video composition in
            player.replaceCurrentItem(with: playerItem) // Vervang de huidige item van de speler
            player.play() // Speel de video af

        } catch {
            print("Fout bij het toepassen van filter: \(error)")
        }
    }

    @objc func addText() {
        overlayText = textInput.text ?? "" // Verkrijg de overlay tekst
        print("Overlay tekst toegevoegd: \(overlayText)")

        // Hier kan de logica worden geïmplementeerd om de overlay tekst op de video toe te voegen
        // Bijvoorbeeld door een UILabel op de video te plaatsen of een tekstlaag te maken in AVComposition
    }

    @objc func trimSliderChanged(_ sender: UISlider) {
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let asset = AVAsset(url: videoURL)
        let duration = asset.duration.seconds // Totale duur van de video
        let trimmedDuration = duration * Double(sender.value) // Bereken de nieuwe duur

        // Creëer een nieuwe AVMutableComposition
        let composition = AVMutableComposition()
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        do {
            // Voeg video- en audiotracks toe met de nieuwe duur
            let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

            let newDuration = CMTime(seconds: trimmedDuration, preferredTimescale: 600)
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: newDuration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: newDuration), of: audioTrack, at: .zero)

            // Vervang de huidige speleritem met de nieuwe compositie
            let playerItem = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: playerItem)
            player.play() // Speel de nieuwe video af

        } catch {
            print("Fout bij het trimmen van de video: \(error)")
        }
    }


    @objc func trimVideo() {
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        print("Trim video")
        print("Slider waarde: \(trimSlider.value)") // Debug info
        let asset = AVAsset(url: videoURL) // Maak een AVAsset van de video
        let composition = AVMutableComposition() // Maak een mutable composition

        // Verkrijg de video en audio tracks
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            // Bereken de nieuwe duur op basis van de sliderwaarde
            let duration = asset.duration.seconds * Double(trimSlider.value)
            let newDuration = CMTime(seconds: duration, preferredTimescale: 600) // Nieuwe duur van de video
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: newDuration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: newDuration), of: audioTrack, at: .zero)

            let playerItem = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: playerItem)
            player.play()

        } catch {
            print("Fout bij het trimmen van de video: \(error.localizedDescription)")
        }
    }




    @objc func exportVideo() {
        guard let composition = player.currentItem?.asset as? AVMutableComposition else {
            print("Huidige item is geen AVMutableComposition")
            return
        }

        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("exportedVideo.mov") // Export pad
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mov

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("Video succesvol geëxporteerd naar: \(exportURL)")
                // Optioneel: sla de video op in de foto bibliotheek
                self.saveVideoToLibrary(url: exportURL)
            case .failed:
                print("Export mislukt: \(String(describing: exportSession.error))")
            case .cancelled:
                print("Export geannuleerd: \(String(describing: exportSession.error))")
            default:
                break
            }
        }
    }

    func saveVideoToLibrary(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            if success {
                print("Video opgeslagen in de fotobibliotheek.")
            } else {
                print("Fout bij het opslaan van de video: \(String(describing: error))")
            }
        }
    }

    // MARK: - UIPickerViewDelegate & UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filters.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filters[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedFilter = filters[row] // Stel het geselecteerde filter in
        print("Filter geselecteerd: \(selectedFilter)")
    }
}

