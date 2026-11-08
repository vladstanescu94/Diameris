import SwiftUI

extension View {
    func saveFailedAlert(isPresented: Binding<Bool>) -> some View {
        alert(String(localized: "Couldn't Save", comment: "Alert title when saving data fails"), isPresented: isPresented) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text(String(localized: "Your changes couldn't be saved. Please try again.", comment: "Alert message when saving data fails"))
        }
    }
}
