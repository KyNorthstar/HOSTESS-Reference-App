//
//  SingleTaskView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-06.
//

import SwiftUI

import HRT



struct SingleTaskView: View {
    var body: some View {
        HStack {
            ProgressiveCheckbox(completion: completion)
        }
    }
}



#Preview {
    SingleTaskView()
}
