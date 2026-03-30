import SwiftUI
import StoreKit

struct PaywallView: View {
    let store: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🤨").font(.system(size: 56))
            Text("Unlock the Full Judgment").font(.title2.bold())

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "person.3.fill", text: "All 6 personality packs")
                featureRow(icon: "bolt.fill", text: "All 7 behavior triggers")
                featureRow(icon: "infinity", text: "Unlimited roasts per day")
                featureRow(icon: "square.and.arrow.up", text: "Daily summary card")
                featureRow(icon: "sparkles", text: "Future updates included")
            }

            Spacer()

            Button {
                Task { try? await store.purchaseFullVersion() }
            } label: {
                VStack(spacing: 2) {
                    Text("Unlock Everything — \(store.fullVersionProduct?.displayPrice ?? "$4.99")")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text("One-time purchase. No subscription.")
                        .font(.caption2).opacity(0.7)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button("Restore Purchase") {
                Task { await store.restorePurchases() }
            }
            .font(.caption).foregroundStyle(.secondary).buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 400, height: 480)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.purple).frame(width: 20)
            Text(text).font(.callout)
        }
    }
}
