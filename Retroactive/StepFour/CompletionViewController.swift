//
//  CompletionViewController.swift
//  Retroactive
//

import Cocoa

class CompletionViewController: NSViewController {
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet weak var congratulatoryLabel: NSTextField!
    @IBOutlet weak var launchAppButton: NSButton!
    @IBOutlet weak var launchAppLabel: NSTextField!
    @IBOutlet weak var behindTheScenesButton: NSButton!
    @IBOutlet weak var clippingView: NSView!
    var confettiView: ConfettiView?
    var allowPatchingAgain: Bool = false
    var justRecreatedLibrary: Bool = false
    
    static func instantiate() -> CompletionViewController
    {
        return NSStoryboard.standard!.instantiateController(withIdentifier: "CompletionViewController") as! CompletionViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if (allowPatchingAgain == true) {
            behindTheScenesButton.title = "Modify {name} again"
            congratulatoryLabel.stringValue = "You have already modified \(placeholderToken).\nThere's usually no need to modify it again."
        }
        congratulatoryLabel.updateToken()
        launchAppLabel.updateToken()
        launchAppLabel.addShadow()
        iconView.updateIcon()
        behindTheScenesButton.updateTitle()
        launchAppLabel.moveIntoView(launchAppButton)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        addConfettiView()
        confettiView?.startConfetti()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(stopConfetti), userInfo: nil, repeats: false)
    }
    
    @objc func stopConfetti() {
        self.confettiView?.stopConfetti()
    }
    
    func addConfettiView() {
        confettiView = ConfettiView(frame: self.view.bounds)
        confettiView?.intensity = 1.5
        if let confetti = confettiView {
            self.view.addSubview(confetti)
        }
    }
    
    func cleariTunesPreferences() {
        let task:Process = Process()
        let pipe:Pipe = Pipe()

        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["delete", "com.apple.iTunes"]
        task.standardOutput = pipe
        task.launch()

        let handle = pipe.fileHandleForReading
        let data = handle.readDataToEndOfFile()
        let result_s = String(data: data, encoding: .utf8)
        print("result is \(result_s ?? "")")
    }
    
    @IBAction func launchAppClicked(_ sender: Any) {
        let openApp = {
            if let knownLocation = AppManager.shared.locationOfChosenApp {
                NSWorkspace.shared.launchApplication(knownLocation)
            }
        }
        if (allowPatchingAgain == true && justRecreatedLibrary == false) {
            openApp()
            return
        }
        if AppManager.shared.chosenApp == .itunes && AppManager.shared.choseniTunesVersion != .darkMode {
            var description = "You have installed an older version of iTunes, which may not be compatible with your current iTunes library.\n\nWould you like to create a new iTunes library to use with iTunes \(AppManager.shared.compatibleVersionOfChosenApp.first ?? "")?"
            let musicFolderPath = ("~/Music" as NSString).expandingTildeInPath
            let standardPath = "\(musicFolderPath)/iTunes"
            let hasiTunesLibraryAtStandardPath = FileManager.default.fileExists(atPath: standardPath)
            if (hasiTunesLibraryAtStandardPath) {
                description = "\(description)\n\nDon't worry. Your existing iTunes library won't be deleted. Instead, it will be renamed."
            }
            AppDelegate.showOptionSheet(title: "Would you like to create a new iTunes library?", text: description, firstButtonText: "Create New Library", secondButtonText: "Don't Create", thirdButtonText: "") { (response) in
                if (response == .alertFirstButtonReturn) {
                    self.cleariTunesPreferences()
                    do {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
                        let dateString = dateFormatter.string(from: Date())
                        try FileManager.default.moveItem(atPath: standardPath, toPath: "\(musicFolderPath)/iTunes \(dateString)")
                    } catch {
                        print(error)
                    }
                    self.justRecreatedLibrary = true
                    openApp()
                } else {
                    openApp()
                }
            }
        } else {
            openApp()
        }
    }
    
    @IBAction func behindTheScenesClicked(_ sender: Any) {
        if (allowPatchingAgain == true) {
            self.navigationController.pushViewController(AuthenticateViewController.instantiate(), animated: true)
            return
        }
        AppDelegate.current.safelyOpenURL(AppManager.shared.behindTheScenesOfChosenApp)
    }

}
