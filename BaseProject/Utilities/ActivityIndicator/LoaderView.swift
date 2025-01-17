//
//  LoaderView.swift
//  BaseProject
//
//  Created by Himanshu Kesharwani on 07/06/23.
//

import Foundation
import SwiftUI

// MARK: - ActivityIndicator

struct ActivityIndicator: UIViewRepresentable {
  typealias UIView = UIActivityIndicatorView

  var isAnimating: Bool = false
  var configuration = { (_: UIView) in }

  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIView { UIView() }
  func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<Self>) {
      if isAnimating {
          uiView.startAnimating()
      } else {
          uiView.stopAnimating()
      }
    configuration(uiView)
  }
}

// MARK: - ActivityIndicatorLoader

struct ActivityIndicatorLoader: UIViewRepresentable {
  @Binding
  var isAnimating: Bool
  let style: UIActivityIndicatorView.Style
  let color: UIColor

  func makeUIView(context: Context) -> UIActivityIndicatorView {
    let indicator = UIActivityIndicatorView(style: style)
      indicator.color = UIColor(named: "#3247E5")
    return indicator
  }

  func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
      if isAnimating == true {
          uiView.startAnimating()
      } else {
          uiView.stopAnimating()
      }
  }
}

// MARK: - ActivityIndicatorView

public struct ActivityIndicatorView: View {
  // MARK: Lifecycle

  public init(isVisible: Binding<Bool>) {
    _isVisible = isVisible
  }

  // MARK: Public

  public var body: some View {
    if isVisible {
      indicator
    } else {
      EmptyView()
    }
  }

  // MARK: Internal

  @Binding
  var isVisible: Bool

  // MARK: Private

  private var indicator: some View {
    ZStack {
        GrowingArcIndicatorView(color: Color(CGColor(gray: 10, alpha: 0.1)), lineWidth: 4)
    }
  }
}

// MARK: - GrowingArcIndicatorView

struct GrowingArcIndicatorView: View {
  // MARK: Public

  public var body: some View {
    let animation = Animation
      .easeIn(duration: 2)
      .repeatForever(autoreverses: false)

    return GrowingArc(path: animatableParameter)
      .stroke(color, lineWidth: lineWidth)
      .onAppear {
        animatableParameter = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
          withAnimation(animation) {
            animatableParameter = 1
          }
        }
      }
  }

  // MARK: Internal

  let color: Color
  let lineWidth: CGFloat

  // MARK: Private

  @State
  private var animatableParameter: Double = 0
}

// MARK: - GrowingArc

struct GrowingArc: Shape {
  var maxLength = 2 * Double.pi - 0.7
  var lag = 0.35
  var path: Double

  var animatableData: Double {
    get { path }
    set { path = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let height = path * 2
    var length = height * maxLength
    if height > 1, height < lag + 1 {
      length = maxLength
    }
    if height > lag + 1 {
      let coeff = 1 / (1 - lag)
      let num = height - 1 - lag
      length = (1 - num * coeff) * maxLength
    }

    let first = Double.pi / 2
    let second = 4 * Double.pi - first

    var end = height * first
    if height > 1 {
      end = first + (height - 1) * second
    }

    let start = end + length

    var path = Path()
      path.addArc(
      center: CGPoint(x: rect.size.width / 2, y: rect.size.width / 2),
      radius: rect.size.width / 2,
      startAngle: Angle(radians: start),
      endAngle: Angle(radians: end),
      clockwise: true
    )
    return path
  }
}
