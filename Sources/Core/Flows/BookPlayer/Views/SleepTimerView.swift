//
//  SleepTimerView.swift
//  visibl
//
//

import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var manager: PlayerManager
    @Binding var showSleepTimerView: Bool
    @Binding var selectedTimerOption: Double
    let timerOptions: [Double] = [0, 300, 600, 900, 1200, 1800, 2700, 3600]
    
    var body: some View {
        VStack {
            makeIndicatorView()
            makeTitleLabelView()
            makeOptionsList()
            Spacer(minLength: 30)
        }
    }
    
    private func makeIndicatorView() -> some View {
        return VStack {
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showSleepTimerView = false
                    }) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(width: 50, height: 5)
                            .cornerRadius(5)
                    }
                    
                    Spacer()
                }
                Spacer()
            }
            .frame(height: 40)
        }
    }
    
    private func makeTitleLabelView() -> some View {
        return HStack {
            
            Text("Sleep Timer")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 10)
    }
    

    
    private func makeOptionsList() -> some View {
        
        let listHeight: CGFloat = max(CGFloat(timerOptions.count) * 44.0, 200)

        return ZStack {
            // Set the background color
            Rectangle()
                .foregroundColor(Color(UIColor.systemBackground))
                .cornerRadius(0)
                .edgesIgnoringSafeArea(.all)
            
            List(timerOptions, id: \.self) { option in
                HStack {
                    Text(timerOptionToString(option))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(selectedTimerOption == option ? .blue : .primary)
                        .padding(.leading, -8)
                    Spacer()
                    if selectedTimerOption == option {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTimerOption = option
                    manager.setSleepTimer(for: selectedTimerOption)
                    self.showSleepTimerView = false
                }
                .listRowBackground(Color.clear)
            }
            .scrollDisabled(true)
            .frame(minHeight: listHeight)
            .listStyle(PlainListStyle())
            .padding(.all, 0)
            .cornerRadius(18)
        }
    }
    
    private func timerOptionToString(_ option: Double) -> String {
        switch option {
        case 0:
            return "Turn off timer"
        case 300:
            return "5 minutes"
        case 600:
            return "10 minutes"
        case 900:
            return "15 minutes"
        case 1200:
            return "20 minutes"
        case 1800:
            return "30 minutes"
        case 2700:
            return "45 minutes"
        case 3600:
            return "1 hour"
        default:
            return "End of episode"
        }
    }
}

struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color(UIColor.systemBackground)
            }
        )
    }
}
