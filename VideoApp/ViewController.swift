import UIKit
import AVFoundation
import Photos

class VideoEditorViewController: UIViewController {

    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: URL?
    var filters = ["none", "CISepiaTone", "CIColorControls"] // Beschikbare filters
    var selectedFilter: String = "none" // Standaardfilter
    var textInput: UITextField! // Invoer voor gebruikers tekst
    var overlayText: String = "" // Plaatsvervanger voor overlay tekst
    var filterPicker: UIPickerView! // Picker voor filters
    var trimSlider: UISlider!
    var stackView: UIStackView! // Houd een referentie naar de stack view

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // Setup UI
    func setupUI() {
        view.backgroundColor = .white

        // Video Player View
        let videoPlayerView = UIView()
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoPlayerView)

        // Constraints voor video player view
        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.heightAnchor.constraint(equalToConstant: 300)
        ])

        // Maak knoppen
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

        // Constraints voor stack view
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: videoPlayerView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Filter Picker
        filterPicker = UIPickerView()
        filterPicker.delegate = self
        filterPicker.dataSource = self
        filterPicker.translatesAutoresizingMaskIntoConstraints = false
        filterPicker.isHidden = true // Aanvankelijk verborgen
        view.addSubview(filterPicker)

        NSLayoutConstraint.activate([
            filterPicker.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            filterPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Trim Slider
        trimSlider = UISlider()
        trimSlider.minimumValue = 0
        trimSlider.maximumValue = 1
        trimSlider.value = 1 // Standaardwaarde (volledige lengte)
        trimSlider.addTarget(self, action: #selector(trimSliderChanged(_:)), for: .valueChanged)
        trimSlider.translatesAutoresizingMaskIntoConstraints = false
        trimSlider.isHidden = true // Aanvankelijk verborgen
        view.addSubview(trimSlider)

        NSLayoutConstraint.activate([
            trimSlider.topAnchor.constraint(equalTo: filterPicker.bottomAnchor, constant: 20),
            trimSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            trimSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Text Input
        textInput = UITextField(frame: CGRect(x: 20, y: 0, width: view.frame.width - 40, height: 40))
        textInput.borderStyle = .roundedRect
        textInput.placeholder = "Enter text to overlay"
        textInput.translatesAutoresizingMaskIntoConstraints = false
        textInput.isHidden = true // Aanvankelijk verborgen
        view.addSubview(textInput)

        NSLayoutConstraint.activate([
            textInput.topAnchor.constraint(equalTo: trimSlider.bottomAnchor, constant: 20),
            textInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // Maak een knop
    func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // Functie om video te importeren
    @objc func importVideo() {
        // Direct een video gebruiken uit het project
        videoURL = Bundle.main.url(forResource: "kobe_berckmans_", withExtension: "mp4")
        if let videoURL = videoURL {
            playVideo(url: videoURL)
            // Zorg ervoor dat alle opties zichtbaar zijn na het importeren van de video
            filterPicker.isHidden = false // Toon de filter picker
            trimSlider.isHidden = false // Toon de trim slider
            textInput.isHidden = false // Toon de tekstinvoer
        } else {
            print("Video niet gevonden")
        }
    }

    // Functie om video af te spelen
    func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)

        player.play()
    }

    // Pas geselecteerde filter toe
    @objc func applyFilter() {
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }
        print("Filter toepassen: \(selectedFilter)")

        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)

            // Maak een video compositie om de filter toe te passen
            let videoComposition = AVMutableVideoComposition(asset: composition) { request in
                let source = request.sourceImage.clampedToExtent()
                var outputImage: CIImage?

                // Pas geselecteerde filter toe
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

                // Geef de output image of source image terug
                request.finish(with: outputImage ?? source, context: nil)
            }

            // Maak AVPlayerItem en speel af
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = videoComposition
            player.replaceCurrentItem(with: playerItem)
            player.play()

        } catch {
            print("Fout bij het toepassen van de filter: \(error)")
        }
    }
    @objc func addText() {
        overlayText = textInput.text ?? ""
        print("Toevoegen tekst: \(overlayText)")

        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)

            let videoComposition = AVMutableVideoComposition(asset: composition) { request in
                let source = request.sourceImage.clampedToExtent()

                // Maak de overlay layer
                let overlayLayer = CALayer()
                overlayLayer.frame = CGRect(origin: .zero, size: source.extent.size)

                // Maak de tekst layer
                let textLayer = CATextLayer()
                textLayer.string = self.overlayText
                textLayer.fontSize = 36
                textLayer.foregroundColor = UIColor.red.cgColor
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.frame = CGRect(x: 0, y: source.extent.height - 100, width: source.extent.width, height: 100)
                overlayLayer.addSublayer(textLayer)

                // Creëer een CIContext om de afbeelding te renderen
                let ciContext = CIContext()

                // Render de video in een CGImage
                guard let cgImage = ciContext.createCGImage(source, from: source.extent) else {
                    print("Fout bij het creëren van CGImage")
                    return request.finish(with: source, context: nil)
                }

                // Begin de context voor het tekenen
                UIGraphicsBeginImageContext(source.extent.size)
                guard let context = UIGraphicsGetCurrentContext() else {
                    print("Kan geen graphics context verkrijgen")
                    return request.finish(with: source, context: nil)
                }

                // Teken de video in de context
                context.draw(cgImage, in: source.extent)

                // Render de overlay layer in de context
                overlayLayer.render(in: context)

                // Verkrijg de nieuwe afbeelding met de overlay
                guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
                    print("Kan de afbeelding niet verkrijgen")
                    UIGraphicsEndImageContext()
                    return request.finish(with: source, context: nil) // Fallback naar de oorspronkelijke afbeelding
                }
                UIGraphicsEndImageContext()

                // Zorg ervoor dat we een CIImage teruggeven
                if let finalCGImage = finalImage.cgImage {
                    request.finish(with: CIImage(cgImage: finalCGImage), context: nil)
                } else {
                    print("Kan de afbeelding niet omzetten naar CIImage")
                    request.finish(with: source, context: nil) // Fallback naar de oorspronkelijke afbeelding
                }
            }

            let playerItem = AVPlayerItem(asset: composition)
            playerItem.videoComposition = videoComposition
            player.replaceCurrentItem(with: playerItem)
            player.play()

        } catch {
            print("Fout bij het toevoegen van tekst: \(error)")
        }
    }


    // Trim video
    @objc func trimVideo() {
        print("Trimmen van video op basis van slider waarde")
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        // Bepaal de trim tijd op basis van slider
        let trimDuration = CMTimeMultiplyByFloat64(asset.duration, multiplier: Float64(trimSlider.value))

        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: trimDuration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: trimDuration), of: audioTrack, at: .zero)

            let playerItem = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: playerItem)
            player.play()

        } catch {
            print("Fout bij het trimmen van de video: \(error)")
        }
    }

    // Update trim slider
    @objc func trimSliderChanged(_ sender: UISlider) {
        print("Trim slider waarde: \(sender.value)")
    }

    // Export video
    @objc func exportVideo() {
        print("Exporteren van de bewerkte video")
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let asset = AVAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video- of audiotrack gevonden.")
            return
        }

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)

            // Export configureren
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
            let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("exported_video.mov")
            exportSession.outputURL = exportURL
            exportSession.outputFileType = .mov

            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    print("Export voltooid: \(exportURL)")
                    // Sla op in fotobibliotheek
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
                    }) { success, error in
                        if success {
                            print("Video opgeslagen in fotobibliotheek")
                        } else {
                            print("Fout bij opslaan in fotobibliotheek: \(String(describing: error))")
                        }
                    }
                case .failed, .cancelled:
                    print("Export mislukt: \(String(describing: exportSession.error))")
                default:
                    break
                }
            }

        } catch {
            print("Fout bij het voorbereiden van de export: \(error)")
        }
    }
}

extension VideoEditorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
        selectedFilter = filters[row]
    }
}
