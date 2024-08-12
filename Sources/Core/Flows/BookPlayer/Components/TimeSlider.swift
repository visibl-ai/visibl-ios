//
//  TimeSlider.swift
//  visibl
//
//

import SwiftUI

struct TimeSlider: View {
    @Binding var time: Double
    let duration: Double
    @State private var isEditing: Bool = false
    @State private var progress: Double = 0
    @State private var color: Color = .white
    
    private var normalFillColor: Color { color.opacity(0.5) }
    private var emptyColor: Color { color.opacity(0.3) }
    
    let nextAction: () -> Void
    let previousAction: () -> Void
    
    var body: some View {
        VStack {
            MusicProgressSlider(
                value: Binding(
                    get: { self.progress * self.duration },
                    set: { newValue in
                        self.progress = newValue / self.duration
                        if !self.isEditing {
                            self.time = newValue
                        }
                    }
                ),
                inRange: 0...duration,
                activeFillColor: color,
                fillColor: normalFillColor,
                emptyColor: emptyColor,
                height: 32,
                onEditingChanged: { editing in
                    self.isEditing = editing
                    if !editing {
                        self.time = self.progress * self.duration
                    }
                },
                nextAction: {
                    nextAction()
                },
                previousAction: {
                    previousAction()
                }
            )
            .frame(height: 40)
            .padding(.top, 12)
        }
        .onChange(of: time) { newValue in
            if !isEditing {
                progress = newValue / duration
            }
        }
    }
}
