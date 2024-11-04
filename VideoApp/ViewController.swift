import UIKit
import AVFoundation
import Photos

class VideoEditorViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var videoURL: URL?
    var filters = ["none", "CISepiaTone", "CIColorControls"]
    var selectedFilter: String = "none"
    var textInput: UITextField!
    var overlayText: String = ""
    var filterPicker: UIPickerView!
    var trimTimeInput: UITextField!
    var stackView: UIStackView!
    var trimSlider: UISlider!
    var videoDuration: Float = 0.0 // Opslaan van de video duur

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = .white

        let videoPlayerView = UIView()
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoPlayerView)

        NSLayoutConstraint.activate([
            videoPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoPlayerView.heightAnchor.constraint(equalToConstant: 300)
        ])

        let importButton = createButton(title: "Import Video", action: #selector(importVideo))
        let applyFilterButton = createButton(title: "Apply Filter", action: #selector(applyFilter))
        let trimButton = createButton(title: "Trim Video", action: #selector(trimVideo))
        let addTextButton = createButton(title: "Add Text", action: #selector(addText))
        let exportButton = createButton(title: "Export Video", action: #selector(exportVideo))

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

        filterPicker = UIPickerView()
        filterPicker.delegate = self
        filterPicker.dataSource = self
        filterPicker.translatesAutoresizingMaskIntoConstraints = false
        filterPicker.isHidden = true
        view.addSubview(filterPicker)

        NSLayoutConstraint.activate([
            filterPicker.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            filterPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Textfield voor het invoeren van trimtijd
        trimTimeInput = UITextField()
        trimTimeInput.borderStyle = .roundedRect
        trimTimeInput.placeholder = "Enter time in seconds to trim"
        trimTimeInput.translatesAutoresizingMaskIntoConstraints = false
        trimTimeInput.keyboardType = .decimalPad
        view.addSubview(trimTimeInput)

        NSLayoutConstraint.activate([
            trimTimeInput.topAnchor.constraint(equalTo: filterPicker.bottomAnchor, constant: 20),
            trimTimeInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            trimTimeInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        textInput = UITextField()
        textInput.borderStyle = .roundedRect
        textInput.placeholder = "Enter text to overlay"
        textInput.translatesAutoresizingMaskIntoConstraints = false
        textInput.isHidden = true
        view.addSubview(textInput)

        NSLayoutConstraint.activate([
            textInput.topAnchor.constraint(equalTo: trimTimeInput.bottomAnchor, constant: 20),
            textInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Slider voor trimtijd
        trimSlider = UISlider()
        trimSlider.minimumValue = 0
        trimSlider.maximumValue = 0 // Dit zal later worden ingesteld op de video duur
        trimSlider.addTarget(self, action: #selector(trimSliderValueChanged(_:)), for: .valueChanged)
        trimSlider.translatesAutoresizingMaskIntoConstraints = false
        trimSlider.isHidden = false // Zorg ervoor dat de slider zichtbaar is
        view.addSubview(trimSlider)

        NSLayoutConstraint.activate([
            trimSlider.topAnchor.constraint(equalTo: textInput.bottomAnchor, constant: 20),
            trimSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            trimSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }


    func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc func importVideo() {
        videoURL = Bundle.main.url(forResource: "kobe_berckmans_", withExtension: "mp4")

        if let videoURL = videoURL {
            playVideo(url: videoURL)
            filterPicker.isHidden = false
            trimTimeInput.isHidden = false
            textInput.isHidden = false
            trimSlider.isHidden = false
        } else {
            print("Video niet gevonden")
        }
    }

    func playVideo(url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 300)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        player.play()

        // Stel de maximale waarde van de slider in op de video lengte
        let duration = CMTimeGetSeconds(player.currentItem?.asset.duration ?? CMTime.zero)
        videoDuration = Float(duration) // Bewaar de duur van de video
        trimSlider.maximumValue = videoDuration
    }

    @objc func trimSliderValueChanged(_ sender: UISlider) {
        let seconds = Int(sender.value)
        trimTimeInput.text = "\(seconds)"
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

                // Geef het resultaat terug met de request.finish() functie
                if let outputImage = outputImage {
                    request.finish(with: outputImage, context: nil) // Geef de gefilterde afbeelding terug
                } else {
                    request.finish(with: source, context: nil) // Geef de originele afbeelding terug als er geen filter is
                }
            }

            let playerItem = AVPlayerItem(asset: composition) // Maak een AVPlayerItem
            playerItem.videoComposition = videoComposition // Stel de video composition in
            player.replaceCurrentItem(with: playerItem) // Vervang de huidige item van de speler
            player.play() // Speel de video af

        } catch {
            print("Fout bij het toepassen van filter: \(error)")
        }
    }


    @objc func trimVideo() {
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }
        
        // Maak een instantie van TrimVideoViewController
        let trimVideoVC = TrimVideoViewController()
        trimVideoVC.videoURL = videoURL // Geef de video URL door
        trimVideoVC.completion = { [weak self] startTime, endTime in
            // Hier kun je de trimming logica implementeren
            self?.performTrimVideo(startTime: startTime, endTime: endTime)
        }
        
        // Presenteer de TrimVideoViewController
        present(trimVideoVC, animated: true, completion: nil)
    }

    func performTrimVideo(startTime: Double, endTime: Double) {
        // Hier kun je de trim logica implementeren
        guard let videoURL = videoURL else {
            print("Video URL is nil")
            return
        }

        let asset = AVAsset(url: videoURL)
        
        // Verkrijg de video en audio tracks
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let audioTrack = asset.tracks(withMediaType: .audio).first else {
            print("Geen video of audio track gevonden.")
            return
        }

        // Maak een nieuwe composition
        let composition = AVMutableComposition()

        // Voeg video track toe aan de composition
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
            let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
            let duration = endCMTime - startCMTime
            
            // Voeg video en audio tracks toe aan de composition
            try compositionVideoTrack?.insertTimeRange(CMTimeRange(start: startCMTime, duration: duration), of: videoTrack, at: .zero)
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: startCMTime, duration: duration), of: audioTrack, at: .zero)

            // Maak een AVPlayerItem van de composition
            let playerItem = AVPlayerItem(asset: composition)
            player.replaceCurrentItem(with: playerItem) // Vervang de huidige item van de speler
            player.play() // Speel de video af
            
            print("Video getrimd van \(startTime) tot \(endTime) seconden")
        } catch {
            print("Fout bij het trimmen van de video: \(error)")
        }
    }


    @objc func addText() {
        overlayText = textInput.text ?? ""
        
        // Voeg tekstlaag toe aan de video
        let textLayer = CATextLayer()
        textLayer.string = overlayText
        textLayer.fontSize = 24
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.frame = CGRect(x: 20, y: 20, width: view.bounds.width - 40, height: 40)
        
        playerLayer.addSublayer(textLayer)
        print("Tekst toegevoegd: \(overlayText)")
    }


    @objc func exportVideo() {
        guard let videoURL = videoURL else {
            print("Geen video URL gevonden voor export.")
            return
        }
        
        let exportSession = AVAssetExportSession(asset: AVAsset(url: videoURL), presetName: AVAssetExportPresetHighestQuality)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("exportedVideo.mp4")
        try? FileManager.default.removeItem(at: outputURL) // Verwijder de vorige export indien deze bestaat
        
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mp4
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                print("Video succesvol geëxporteerd naar: \(outputURL)")
            case .failed:
                print("Export mislukt: \(String(describing: exportSession?.error))")
            case .cancelled:
                print("Export geannuleerd.")
            default:
                break
            }
        }
    }

    // MARK: - PickerView DataSource Methods

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
        print("Geselecteerd filter: \(selectedFilter)")
    }
}

