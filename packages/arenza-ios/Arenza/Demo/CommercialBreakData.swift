// CommercialBreakData.swift — Arenza
// iOS port of web demo gameData.ts — CommercialBreak catalog.
// Real local restaurant & bar video ads with exact durations and URLs.
//
// Matches web demo COMMERCIAL_BREAKS exactly:
//   break-1  t=15   Rooftop Gardens short (17s)
//   break-2  t=50   AJ.Ward            (31s)
//   break-3  t=95   Rocco's #1         (31s)
//   break-4  t=140  Bonsai Cafe        (34s)
//   break-5  t=190  Old Ram            (29s)
//   break-6  t=235  Rooftop Gardens #2 (34s)
//   break-7  t=280  Rocco's #2         (34s)

import Foundation
import SwiftUI

// MARK: - Data Models

struct AdCreative: Identifiable {
    let id: String
    let brand: String
    let tagline: String
    let emoji: String
    let color: String         // hex e.g. "#588157"
    let cpm: Int
    let durationSec: Int
    let videoURL: URL?
    let websiteURL: URL?
    let offerHeadline: String
    let offerValue: String
    let targetSegment: String

    var primaryColor: Color { Color(arenza: color) }
}

struct CommercialBreak: Identifiable {
    let id: String
    let triggerAt: Int        // game-clock seconds
    let label: String
    let ads: [AdCreative]
}

// MARK: - Ad Catalog

private func url(_ s: String) -> URL? { URL(string: s) }

let AD_AJWARD = AdCreative(
    id: "ad-ajward", brand: "AJ.Ward", tagline: "Fine dining, unforgettable moments",
    emoji: "🍽️", color: "#1a1a2e", cpm: 45, durationSec: 31,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/AJ.WARD.mp4"),
    websiteURL: url("https://www.ajward.co.uk"),
    offerHeadline: "Game Day — 15% Off Dining",
    offerValue: "15% off your bill",
    targetSegment: "Foodies · Local Diners 25–54"
)

let AD_BONSAI = AdCreative(
    id: "ad-bonsai", brand: "Bonsai Cafe", tagline: "Where food meets art",
    emoji: "🍜", color: "#2d6a4f", cpm: 38, durationSec: 34,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/Bonsai%20Cafe.mp4"),
    websiteURL: url("https://thedojonorwich.co.uk/bonsai-cafe/"),
    offerHeadline: "Free Miso Soup on $25+",
    offerValue: "Free miso soup",
    targetSegment: "Health-Conscious · Cafe Culture 18–44"
)

let AD_ROCCOS_1 = AdCreative(
    id: "ad-roccos-1", brand: "Rocco's Bar & Restaurant", tagline: "Live it up at Rocco's",
    emoji: "🍸", color: "#e63946", cpm: 42, durationSec: 31,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/ROCCOS%20BAR%20%26%20RESTURANT%201.mp4"),
    websiteURL: url("http://www.roccos.com"),
    offerHeadline: "$5 Draft Beer — Game Day Special",
    offerValue: "$5 drafts all night",
    targetSegment: "Nightlife & Dining · 21–45"
)

let AD_ROCCOS_2 = AdCreative(
    id: "ad-roccos-2", brand: "Rocco's Bar & Restaurant", tagline: "Great food, great times",
    emoji: "🍕", color: "#c1121f", cpm: 42, durationSec: 34,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/ROCCOS%20BAR%20%26%20RESTURANT%202.mp4"),
    websiteURL: url("http://www.roccos.com"),
    offerHeadline: "Free Garlic Bread with Pizza",
    offerValue: "Free garlic bread",
    targetSegment: "Nightlife & Dining · 21–45"
)

let AD_ROOFTOP_1 = AdCreative(
    id: "ad-rooftop-1", brand: "Rooftop Gardens", tagline: "Elevated dining, stunning views",
    emoji: "🌿", color: "#588157", cpm: 52, durationSec: 17,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/Rooftop%20Gardens%202.mp4"),
    websiteURL: url("https://rooftopgardens.co.uk/"),
    offerHeadline: "Rooftop Happy Hour — 20% Off",
    offerValue: "20% off drinks",
    targetSegment: "Premium Diners · Date Night 25–54"
)

let AD_ROOFTOP_2 = AdCreative(
    id: "ad-rooftop-2", brand: "Rooftop Gardens", tagline: "Drinks with a view",
    emoji: "🍹", color: "#3a5a40", cpm: 52, durationSec: 34,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/Rooftop%20Gardens%203.mp4"),
    websiteURL: url("https://rooftopgardens.co.uk/"),
    offerHeadline: "Reserve a Rooftop Table Tonight",
    offerValue: "Priority seating",
    targetSegment: "Premium Diners · Date Night 25–54"
)

let AD_OLDRAM = AdCreative(
    id: "ad-oldram", brand: "Old Ram Coaching Inn", tagline: "History, charm & great ales",
    emoji: "🍺", color: "#7c5c3e", cpm: 35, durationSec: 29,
    videoURL: url("https://lavcma6duvpplftv.public.blob.vercel-storage.com/Old%20Ram%20Coaching%20Inn%20.mp4"),
    websiteURL: url("https://theoldramfreehouse.com/"),
    offerHeadline: "First Pint on Us — Join the Inn",
    offerValue: "Free first pint",
    targetSegment: "Pub & Inn Lovers · All Ages"
)

// MARK: - Commercial Break Schedule (mirrors web demo exactly)

let COMMERCIAL_BREAKS: [CommercialBreak] = [
    CommercialBreak(id: "break-1", triggerAt: 15,  label: "Commercial Break", ads: [AD_ROOFTOP_1]),
    CommercialBreak(id: "break-2", triggerAt: 50,  label: "Commercial Break", ads: [AD_AJWARD]),
    CommercialBreak(id: "break-3", triggerAt: 95,  label: "Commercial Break", ads: [AD_ROCCOS_1]),
    CommercialBreak(id: "break-4", triggerAt: 140, label: "Commercial Break", ads: [AD_BONSAI]),
    CommercialBreak(id: "break-5", triggerAt: 190, label: "Commercial Break", ads: [AD_OLDRAM]),
    CommercialBreak(id: "break-6", triggerAt: 235, label: "Commercial Break", ads: [AD_ROOFTOP_2]),
    CommercialBreak(id: "break-7", triggerAt: 280, label: "Commercial Break", ads: [AD_ROCCOS_2]),
]
