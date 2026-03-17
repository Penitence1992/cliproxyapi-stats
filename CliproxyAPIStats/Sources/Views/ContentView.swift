import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(viewModel: viewModel)
            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    SummarySection(summaries: viewModel.groupSummaries)
                    Divider().padding(.horizontal)
                    AccountListSection(usages: viewModel.accountUsages)
                }
            }

            Divider()
            FooterView(viewModel: viewModel)
        }
        .frame(width: 380, height: 500)
        .onAppear { viewModel.start() }
    }
}
