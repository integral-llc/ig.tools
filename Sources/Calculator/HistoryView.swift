import SwiftUI

/// Standalone history view (reusable if needed outside main calculator).
struct HistoryView: View {
    let entries: [HistoryEntry]
    let copiedEntryID: UUID?
    let onCopy: (HistoryEntry) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if entries.isEmpty {
                Text("No history yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries) { entry in
                            HistoryRowView(
                                entry: entry,
                                isCopied: copiedEntryID == entry.id
                            ) {
                                onCopy(entry)
                            }
                        }
                    }
                }

                Divider()

                HStack {
                    Spacer()
                    Button("Clear History") { onClear() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }
}
