// SCTE35Detector.swift
// AVPlayerItemMetadataOutputPushDelegate that fires when an SCTE-35
// splice insert is detected in the HLS/DASH manifest.

import AVFoundation

// ── Delegate protocol ─────────────────────────────────────────────────────────
protocol SCTE35DetectorDelegate: AnyObject {
    func scte35Detected(duration: Double, cueId: String)
}

// ── SCTE-35 cue model ─────────────────────────────────────────────────────────
struct SCTE35Cue {
    var spliceEventId: String = ""
    var breakDuration: Double = 30.0
    var immediate: Bool = false
}

// ── Detector ──────────────────────────────────────────────────────────────────
final class SCTE35Detector: NSObject, AVPlayerItemMetadataOutputPushDelegate {

    weak var delegate: SCTE35DetectorDelegate?

    // Called by AVFoundation on the queue passed to setDelegate(_:queue:)
    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        for group in groups {
            for item in group.items {
                guard let keyStr = item.key as? String else { continue }

                // HLS EXT-X-DATERANGE / SCTE-35 markers
                // Common identifiers used by AWS MediaTailor, VideoJS, etc.
                let isScte = keyStr.contains("SCTE") ||
                             keyStr.contains("scte") ||
                             keyStr == "com.apple.quicktime.HLS" ||
                             item.identifier?.rawValue.contains("scte35") == true

                if isScte {
                    let cue = parseSCTE35(item: item)
                    print("[SCTE-35] Splice insert detected: id=\(cue.spliceEventId) duration=\(cue.breakDuration)s")
                    delegate?.scte35Detected(duration: cue.breakDuration, cueId: cue.spliceEventId)
                    return
                }
            }
        }
    }

    // ── Parse SCTE-35 binary payload ─────────────────────────────────────────
    // Full SCTE 35 2022 binary parsing is complex — this covers the key fields.
    private func parseSCTE35(item: AVMetadataItem) -> SCTE35Cue {
        var cue = SCTE35Cue()
        cue.spliceEventId = item.extraAttributes?[.init(rawValue: "CAID")] as? String
            ?? "cue-\(Int.random(in: 10000...99999))"

        // Extract break duration from EXT-X-DATERANGE DURATION attribute
        if let duration = item.extraAttributes?[.init(rawValue: "DURATION")] as? Double {
            cue.breakDuration = duration
        } else if let data = item.dataValue, data.count > 14 {
            // Binary SCTE-35: splice_info_section
            // Break duration is at offset 14 bytes in a basic splice_insert
            // Byte 14-15: break_duration flags + 33-bit tick
            let ticks = (UInt64(data[14] & 0x01) << 32) | UInt64(data[15]) << 24 |
                        UInt64(data[16]) << 16  | UInt64(data[17]) << 8 | UInt64(data[18])
            cue.breakDuration = Double(ticks) / 90000.0  // 90kHz clock → seconds
        }

        return cue
    }
}
