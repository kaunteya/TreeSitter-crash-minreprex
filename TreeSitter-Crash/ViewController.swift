//
//  ViewController.swift
//  TreeSitter-Crash
//
//  Created by Kauntey Suryawanshi on 06/08/23.
//

import Cocoa
import Neon
import SwiftTreeSitter
import TreeSitterClient
import TreeSitterJSON

class ViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    var highlighter: Highlighter!
    let textStorage = NSTextStorage()
    let treeSitterClient: TreeSitterClient
    let query: Query

    required init?(coder: NSCoder) {
        let language = Language(language: tree_sitter_json())
        treeSitterClient = try! TreeSitterClient(language: language)
        query = try! language.query(contentsOf: Bundle.main.url(forResource: "highlights", withExtension: "scm")!)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.textStorage?.delegate = self
        treeSitterClient.invalidationHandler = { [weak self] indexSet in
            self?.highlighter.invalidate(.set(indexSet))
        }

        let textInterface = TextViewSystemInterface(textView: textView, attributeProvider: attributeProvider)
        let tokenProvider = treeSitterClient.tokenProvider(with: query)
        self.highlighter = Highlighter(textInterface: textInterface, tokenProvider: tokenProvider)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        textView.string = #"{"name": "Neon"}"#
    }

    private func attributeProvider(_ token: Token) -> [NSAttributedString.Key: Any]? {
        switch token.name {
        case "punctuation.bracket": return [.foregroundColor: NSColor.systemRed]
        case "punctuation.delimiter": return [.foregroundColor: NSColor.secondaryLabelColor]
        case "keyword": return [.foregroundColor: NSColor.systemOrange]
        case "value.string": return [.foregroundColor: NSColor.systemGreen]
        case "value.bool": return [.foregroundColor: NSColor.systemIndigo]
        case "value.number": return [.foregroundColor: NSColor.systemPurple]
        case "value.null": return [.foregroundColor: NSColor.systemCyan]
        case "error": return [.foregroundColor: NSColor.labelColor, .backgroundColor: NSColor.systemRed]
        default: return [.foregroundColor: NSColor.systemGray, .backgroundColor: NSColor.systemGreen]
        }
    }
}

extension ViewController: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        treeSitterClient.willChangeContent(in: editedRange)
    }

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        let adjustedRange = NSRange(location: editedRange.location, length: editedRange.length - delta)
        self.highlighter.didChangeContent(in: adjustedRange, delta: delta)
        treeSitterClient.didChangeContent(to: textStorage.string, in: adjustedRange, delta: delta, limit: textStorage.string.count)
    }
}

extension ViewController {
    func node() async throws -> Node? {
        let currentTree = try await treeSitterClient.currentTree()
        let root = currentTree.rootNode!.firstChild!
        print(root.parent) // <- Does not crash here
        return root
    }

    func getPath() {
        Task { @MainActor in
            let node = try! await node()!
            print(node.parent) // <- But crashes here
        }
    }

    @IBAction func testButtonClicked(_ sender: Any) {
        getPath()
    }
}
