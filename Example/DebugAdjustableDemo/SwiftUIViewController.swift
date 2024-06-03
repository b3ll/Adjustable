//
//  SwiftUIViewController.swift
//  DebugAdjustableDemo
//
//  Created by Adam Bell on 6/2/24.
//

import DebugAdjustable
import SwiftUI

class Model: ObservableObject {

    @DebugAdjustable(0.0...Double.pi) var rotation: Double = 0.0
    @DebugAdjustable(0.0...2.0) var response: Double = 0.3
    @DebugAdjustable(0.0...1.0) var dampingFraction: Double = 1.0

}

struct SwiftUIView: View {

    @StateObject var model = Model()

    @State var pressed: Bool = false

    var body: some View {
        Image("DebugAdjustable")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(24.0)
            .rotation3DEffect(
                .init(radians: model.rotation),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
            .scaleEffect(pressed ? CGSize(width: 0.8, height: 0.8) : CGSize(width: 1.0, height: 1.0))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        withAnimation(.spring(response: model.response, dampingFraction: model.dampingFraction)) {
                            self.pressed = true
                        }
                    })
                    .onEnded({ _ in
                        withAnimation(.spring(response: model.response, dampingFraction: model.dampingFraction)) {
                            self.pressed = false
                        }
                    })
            )
            .scaleEffect(CGSize(width: 0.8, height: 0.8))
    }
}


#Preview {
    SwiftUIView()
}
