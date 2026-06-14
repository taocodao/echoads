// ArenzaSplitView.swift — Arenza (ArenzaTV Prototype)
// 3-state draggable split-screen container:
//   1. Full Video  — video fills screen, companion panel hidden (grabber only)
//   2. Split View  — video ~45%, companion ~55% with tab bar
//   3. Panel Focus — mini-player strip (72pt), expanded companion panel
//
// Uses a DragGesture-driven offset with spring snapping to three detent positions.
// Replaces the existing 40/60 fixed split in PlayerView with a user-controllable layout.

import SwiftUI

// MARK: - Split State

enum SplitState: CaseIterable {
    case fullVideo   // Video 100%, panel hidden
    case splitView   // Video ~45%, panel ~55%
    case panelFocus  // Mini-player 72pt, panel expanded

    var videoFraction: CGFloat {
        switch self {
        case .fullVideo:  return 1.0
        case .splitView:  return 0.42
        case .panelFocus: return 0.0    // mini-player strip used instead
        }
    }

    var label: String {
        switch self {
        case .fullVideo:  return "Full Video"
        case .splitView:  return "Split View"
        case .panelFocus: return "Panel Focus"
        }
    }
}

// MARK: - ArenzaSplitView

struct ArenzaSplitView<VideoContent: View, PanelContent: View>: View {
    let videoContent: VideoContent
    let panelContent: PanelContent
    let miniPlayerHeight: CGFloat = 72

    @Binding var state: SplitState
    @State private var dragOffset: CGFloat = 0

    init(
        state: Binding<SplitState>,
        @ViewBuilder video: () -> VideoContent,
        @ViewBuilder panel: () -> PanelContent
    ) {
        self._state = state
        self.videoContent = video()
        self.panelContent = panel()
    }

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let videoHeight = computeVideoHeight(totalHeight: totalHeight)

            VStack(spacing: 0) {
                // Video section
                ZStack {
                    videoContent
                        .frame(height: max(miniPlayerHeight, videoHeight + dragOffset))
                        .clipped()

                    // Mini-player overlay (score strip) when in panelFocus
                    if state == .panelFocus && dragOffset.magnitude < 20 {
                        miniPlayerStrip
                            .frame(height: miniPlayerHeight)
                            .transition(.opacity)
                    }
                }
                .frame(height: max(miniPlayerHeight, videoHeight + dragOffset))

                // Grabber handle
                grabberHandle
                    .gesture(dragGesture(totalHeight: totalHeight))

                // Panel section — only visible in splitView and panelFocus
                if state != .fullVideo || dragOffset < -30 {
                    panelContent
                        .frame(maxHeight: .infinity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: state)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: dragOffset)
    }

    // MARK: - Compute Heights

    private func computeVideoHeight(totalHeight: CGFloat) -> CGFloat {
        switch state {
        case .fullVideo:
            return totalHeight - 28  // leave room for grabber
        case .splitView:
            return totalHeight * 0.42
        case .panelFocus:
            return miniPlayerHeight
        }
    }

    // MARK: - Grabber Handle

    private var grabberHandle: some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(Color.white.opacity(state == .fullVideo ? 0.4 : 0.2))
                .frame(width: 40, height: 4)

            if state == .fullVideo {
                Text("Swipe up to play games")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.35))
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: state == .fullVideo ? 28 : 20)
        .background(Color(arenza: "#0d0f14"))
        .contentShape(Rectangle())
    }

    // MARK: - Mini-Player Strip

    private var miniPlayerStrip: some View {
        HStack(spacing: 12) {
            // Tiny video thumbnail area (the video is already showing behind this)
            Spacer()

            // Score display
            HStack(spacing: 8) {
                Text("🦅 EAGLES")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#ff6b35"))
                Text("vs")
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.4))
                Text("BEARS 🐻")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(arenza: "#00c9b1"))
            }

            Spacer()

            // Live badge
            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 5, height: 5)
                Text("LIVE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.red)
                    .tracking(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.85), Color.black.opacity(0.65)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    // MARK: - Drag Gesture

    private func dragGesture(totalHeight: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.height * 0.6  // dampened
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height
                let threshold: CGFloat = 60

                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    switch state {
                    case .fullVideo:
                        if value.translation.height < -threshold || velocity < -200 {
                            state = .splitView
                        }
                    case .splitView:
                        if value.translation.height > threshold || velocity > 200 {
                            state = .fullVideo
                        } else if value.translation.height < -threshold || velocity < -200 {
                            state = .panelFocus
                        }
                    case .panelFocus:
                        if value.translation.height > threshold || velocity > 200 {
                            state = .splitView
                        }
                    }
                    dragOffset = 0
                }
            }
    }
}
