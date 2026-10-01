import SwiftUI

#if canImport(ContactsUI)
import ContactsUI
import Contacts
#endif

#if canImport(UIKit)
import UIKit
#endif

struct ContactInviteSelection: Identifiable, Equatable {
    var id: String { "\(name)-\(phone ?? email ?? "")" }
    let name: String
    let phone: String?
    let email: String?
}

#if canImport(ContactsUI) && canImport(UIKit)
struct ContactInvitePicker: UIViewControllerRepresentable {
    var onPick: (ContactInviteSelection) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0 OR emailAddresses.@count > 0"
        )
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (ContactInviteSelection) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (ContactInviteSelection) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Friend"
            let phone = contact.phoneNumbers.first?.value.stringValue
            let email = contact.emailAddresses.first?.value as String?
            onPick(ContactInviteSelection(name: name, phone: phone, email: email))
        }
    }
}
#endif

struct ShareInviteSheet: Identifiable {
    let id = UUID()
    let items: [Any]
}

#if canImport(UIKit)
struct ActivityShareView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
