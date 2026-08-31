import AVFoundation

/// A phone macOS is currently exposing over Continuity.
///
/// It arrives as two separate `AVCaptureDevice`s — camera and microphone — that share a
/// `uniqueID` apart from its last four characters, which is what pairs them back into one
/// device here. Note that a Continuity camera reports as `.external`, not `.continuityCamera`,
/// so the model ID is what actually identifies it as a phone.
struct Phone: Identifiable {
    let id: String
    let name: String
    let model: String
    let camera: AVCaptureDevice?
    let microphone: AVCaptureDevice?

    var summary: String {
        [state("Camera", camera), state("Mic", microphone)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func state(_ kind: String, _ device: AVCaptureDevice?) -> String? {
        guard let device else { return nil }
        if !device.isConnected { return "\(kind): disconnected" }
        if device.isInUseByAnotherApplication { return "\(kind): in use" }
        if device.isSuspended { return "\(kind): suspended" }
        return "\(kind): ready"
    }
}

enum Status {
    static func phones() -> [Phone] {
        let devices = discover(.video, [.continuityCamera, .external])
            + discover(.audio, [.microphone, .external])
        return Dictionary(grouping: devices) { String($0.uniqueID.dropLast(4)) }
            .map(phone)
            .sorted { $0.name < $1.name }
    }

    /// `localizedName` is the phone's own name plus a role word — "Swing Camera", "Swing
    /// Microphone". Dropping the last word gets back to what the user named the phone.
    static func baseName(_ name: String) -> String {
        let words = name.split(separator: " ")
        return words.count > 1 ? words.dropLast().joined(separator: " ") : name
    }

    private static func phone(id: String, devices: [AVCaptureDevice]) -> Phone {
        let camera = devices.first { $0.hasMediaType(.video) }
        let microphone = devices.first { $0.hasMediaType(.audio) }
        let primary = camera ?? microphone
        return Phone(
            id: id,
            name: baseName(primary?.localizedName ?? "Unknown"),
            model: camera?.modelID ?? primary?.modelID ?? "",
            camera: camera,
            microphone: microphone
        )
    }

    private static func discover(
        _ media: AVMediaType, _ types: [AVCaptureDevice.DeviceType]
    ) -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: media, position: .unspecified)
            .devices
            .filter { $0.modelID.hasPrefix("iPhone") || $0.modelID.hasPrefix("iPad") }
    }
}
