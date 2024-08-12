//
//  View+Modifiers.swift
//  visibl
//
//

import SwiftUI

struct RectangleBackground: ViewModifier {
    let strokeColor: Color
    let backgroundColor: Color
    let shouldApply: Bool
    let cornerRadius: Double
    
    func body(content: Content) -> some View {
        if shouldApply {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: 0.5)
                    .stroke(strokeColor, lineWidth : 0)
                    .background(backgroundColor)
                content
            }
            .cornerRadius(cornerRadius)
        }
        else {
            content
        }
    }
}

extension View {
    func rectangleBackground(
        with strokeColor: Color,
        backgroundColor: Color,
        cornerRadius: Double,
        shouldApply: Bool = true
    ) -> some View {
        
        return self.modifier(
            RectangleBackground(
                strokeColor: strokeColor,
                backgroundColor: backgroundColor,
                shouldApply: shouldApply,
                cornerRadius: cornerRadius
            )
        )
    }
}
