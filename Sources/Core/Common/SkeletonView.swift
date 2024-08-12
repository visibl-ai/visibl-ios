//
//  SkeletonView.swift
//  visibl
//
//

import SwiftUI

class SkeletonUIView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSwiftUIView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwiftUIView()
    }
    
    private func setupSwiftUIView() {
        let swiftUIView = SkeletonView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

struct SkeletonView: View {
    var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 12) {
                ForEach(0..<9) { _ in
                    VStack (spacing: 4) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 170)
                            .cornerRadius(8)
                            .blinking()
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 10)
                            .cornerRadius(4)
                            .blinking()
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 10)
                            .cornerRadius(4)
                            .blinking()
                    }
                }
            }
            .padding(EdgeInsets(top: 16, leading: 14, bottom: 20, trailing: 14))
        }
    }
}

struct BlinkViewModifier: ViewModifier {
    let duration: Double
    @State private var blinking: Bool = false
    
    func body(content: Content) -> some View {
        content
            .opacity(blinking ? 0.3 : 1)
            .animation(.easeInOut(duration: duration).repeatForever(), value: blinking)
            .onAppear {
                blinking.toggle()
            }
    }
}

extension View {
    func blinking(duration: Double = 1) -> some View {
        modifier(BlinkViewModifier(duration: duration))
    }
}
