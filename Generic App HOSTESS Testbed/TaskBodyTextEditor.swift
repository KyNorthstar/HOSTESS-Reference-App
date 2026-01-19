//
//  TaskBodyTextEditor.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-15.
//

import SwiftUI

import BasicMathTools
import FunctionTools



#if canImport(AppKit)
struct TaskBodyTextEditor: NSViewRepresentable {
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.lineLimit)
    private var lineLimit
    
    @Environment(\.multilineTextAlignment)
    private var alignment
    
    @Binding
    var text: AttributedString
    var font: NSFont?
    var minHeight: CGFloat = 20
    var maxHeight: CGFloat = .infinity
    
    let onComplete: () -> Void
    
    
    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.drawsBackground = false
        textView.delegate = context.coordinator
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        return textView
    }
    
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        let attributedText = NSAttributedString(text)
        if nsView.attributedString() != attributedText {
            nsView.textStorage?.setAttributedString(attributedText)
        }
        
        nsView.font = font ?? .preferredFont(forTextStyle: .body)
        
        nsView.appearance = NSAppearance(named: (colorScheme == .dark) ? .darkAqua : .aqua)
        nsView.textColor = .textColor
        
        let paragraphStyle = NSMutableParagraphStyle()
        switch alignment {
        case .leading: paragraphStyle.alignment = .left
        case .center: paragraphStyle.alignment = .center
        case .trailing: paragraphStyle.alignment = .right
        }
        nsView.typingAttributes[.paragraphStyle] = paragraphStyle
        nsView.textStorage?.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: nsView.string.count), options: []) { _, range, _ in
            nsView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }

        DispatchQueue.main.async {
            adjustHeight(textView: nsView)
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TaskBodyTextEditor
        init(_ parent: TaskBodyTextEditor) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Enforce lineLimit if provided
            if let lineLimit = parent.lineLimit, lineLimit > 0 {
                let lines = textView.string.components(separatedBy: .newlines)
                if lines.count > lineLimit {
                    let allowed = lines.prefix(lineLimit).joined(separator: "\n")
                    textView.string = allowed
                }
            }
            
            DispatchQueue.main.async {
                self.parent.text = AttributedString(textView.attributedString())
                self.parent.adjustHeight(textView: textView)
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Return key to end editing
            if commandSelector == #selector(NSTextView.insertNewline(_:)) {
                // Return key without modifiers - resign first responder to stop editing
                textView.window?.makeFirstResponder(textView.superview)
                parent.onComplete()
                return true
            }
            // Shift+Return is handled by insertNewlineIgnoringFieldEditor:
            // which allows the newline to be inserted normally
            return false
        }
    }
    
    private func adjustHeight(textView: NSTextView) {
        guard let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }
        let size = layoutManager.usedRect(for: textContainer).size
        let newHeight = clamp(min: minHeight, value: size.height + textView.textContainerInset.height * 2, max: maxHeight)
        textView.removeConstraints(textView.constraints)
        NSLayoutConstraint.activate([
            textView.heightAnchor.constraint(equalToConstant: newHeight),
            textView.widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
        ])
        if textView.frame.height != newHeight {
            textView.frame.size.height = newHeight
            textView.needsLayout = true
        }
    }
    
    
    
    
    typealias NSViewType = NSTextView
}

#else
struct TaskBodyTextEditor: UIViewRepresentable {
    @Binding var text: AttributedString
    var minHeight: CGFloat = 20
    var maxHeight: CGFloat = .infinity
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .infinity))
            uiView.frame.size.height = max(minHeight, min(size.height, maxHeight))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ResizableTextEditor
        init(_ parent: ResizableTextEditor) { self.parent = parent }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            DispatchQueue.main.async {
                let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity))
                textView.frame.size.height = max(parent.minHeight, min(size.height, parent.maxHeight))
            }
        }
    }
}
#endif


#Preview {
    @Previewable @State
    var bodyText: AttributedString = try! .init(markdown: """
            
            # Lorem ipsum
            
            ~~dolor~~ _sit_ **amet**
            
            > And all that jazz
            
            """)
    
    VStack {
        TaskBodyTextEditor(text: $bodyText, onComplete: null)
            .lineLimit(2)
            .border(.blue)
        
        Text(bodyText)
            .colorScheme(.dark)
            .background(.black)
        Text(bodyText)
            .colorScheme(.light)
            .background(.white)
    }
}
