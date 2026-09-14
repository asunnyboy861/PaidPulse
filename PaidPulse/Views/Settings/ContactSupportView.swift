import SwiftUI
import SwiftData

struct ContactSupportView: View {
    @State private var selectedSubject = "General"
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @FocusState private var messageFocused: Bool

    private let backendURL = "https://feedback-board.iocompile67692.workers.dev/api/feedback"
    private let maxMessageLength = 1000

    private static let subjects: [(String, String)] = [
        ("General", "bubble.left.fill"),
        ("Feature Suggestion", "lightbulb.fill"),
        ("Bug Report", "ant.fill"),
        ("Usage Question", "questionmark.circle.fill"),
        ("Performance Issue", "gauge.with.dots.needle.67percent"),
        ("UI Improvement", "paintpalette.fill"),
        ("Other", "ellipsis.circle.fill")
    ]

    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty &&
        (selectedSubject != "Other" || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var resolvedSubject: String {
        selectedSubject == "Other" ? customSubject.trimmingCharacters(in: .whitespaces) : selectedSubject
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                subjectGrid
                if selectedSubject == "Other" {
                    TextField("Tell us the topic…", text: $customSubject)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                fieldLabel("Name")
                TextField("Your name", text: $name)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("Your name")
                fieldLabel("Email")
                TextField("yourname@example.com", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("Email address")
                if !email.isEmpty && !isValidEmail {
                    Text("Please enter a valid email address.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                fieldLabel("Message")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $message)
                        .focused($messageFocused)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onChange(of: message) { _, newValue in
                            if newValue.count > maxMessageLength {
                                message = String(newValue.prefix(maxMessageLength))
                            }
                        }
                        .accessibilityLabel("Feedback message")
                    if message.isEmpty {
                        Text("Tell us what's on your mind…")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 16)
                            .padding(.leading, 13)
                            .allowsHitTesting(false)
                    }
                }
                HStack {
                    Spacer()
                    Text("\(message.count) / \(maxMessageLength)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                submitButton
                Text("We only use your email to respond to this feedback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Thank you!", isPresented: $showSuccess) {
            Button("Done", role: .cancel) {
                resetForm()
            }
        } message: {
            Text("Your feedback has been sent.")
        }
        .alert("Couldn't send", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
    }

    private var subjectGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            fieldLabel("What's it about?")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Self.subjects.prefix(6), id: \.0) { subject, symbol in
                    subjectTile(subject, symbol: symbol)
                }
                subjectTile("Other", symbol: "ellipsis.circle.fill", spansFullWidth: true)
            }
        }
    }

    private func subjectTile(_ subject: String, symbol: String, spansFullWidth: Bool = false) -> some View {
        let isSelected = selectedSubject == subject
        return Button {
            selectedSubject = subject
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: symbol)
                        .font(.title3)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color(.systemBackground))
                    }
                }
                Text(subject)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color(.systemFill), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(subject), \(isSelected ? "selected" : "not selected")")
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.bold())
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Submit")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSubmit || isSubmitting)
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "PaidPulse"
        let payload = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: resolvedSubject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: appName
        )
        guard let url = URL(string: backendURL),
              let body = try? JSONEncoder().encode(payload) else {
            isSubmitting = false
            errorMessage = "Something went wrong. Please try again."
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 20
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error {
                    errorMessage = error.localizedDescription
                    return
                }
                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    showSuccess = true
                } else {
                    errorMessage = "Something went wrong. Please try again."
                }
            }
        }.resume()
    }

    private func resetForm() {
        selectedSubject = "General"
        customSubject = ""
        name = ""
        email = ""
        message = ""
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
