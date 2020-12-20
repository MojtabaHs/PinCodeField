//
//  PinCodeItem.swift
//  PinCodeField
//
//  Created by Seyed Mojtaba Hosseini Zeidabadi on 12/20/20.
//  Copyright © 2020 Alibaba. All rights reserved.
//
//  StackOverflow: https://stackoverflow.com/story/mojtabahosseini
//  Linkedin: https://linkedin.com/in/MojtabaHosseini
//  GitHub: https://github.com/MojtabaHs
//

import UIKit

class PinCodeItem: UITextField {

    var deleteButtonAction: PinCodeViewDeleteButtonAction = .deleteCurrentAndMoveToPrevious

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let excludeAction = [
            #selector(UIResponderStandardEditActions.cut),
            #selector(UIResponderStandardEditActions.copy),
            #selector(UIResponderStandardEditActions.delete),
            #selector(UIResponderStandardEditActions.select),
            #selector(UIResponderStandardEditActions.selectAll)
        ]

        guard !excludeAction.contains(action) else { return false }
        return super.canPerformAction(action, withSender: sender)
    }

    override func deleteBackward() {

        let isBackSpace = { () -> Bool in
            guard let char = self.text?.cString(using: String.Encoding.utf8) else { return false }
            return strcmp(char, "\\b") == -92
        }

        switch deleteButtonAction {
        case .deleteCurrentAndMoveToPrevious:
            // Move cursor from the beginning (set in shouldChangeCharIn:) to the end for deleting
            selectedTextRange = textRange(from: endOfDocument, to: beginningOfDocument)
            super.deleteBackward()

            if isBackSpace(), let nextResponder = superview?.superview?.superview?.superview?.viewWithTag(tag - 1) as UIResponder? {
                nextResponder.becomeFirstResponder()
            }
        case .deleteCurrent:
            if text?.isEmpty == false {
                super.deleteBackward()
            } else {
                // Move cursor from the beginning (set in shouldChangeCharIn:) to the end for deleting
                selectedTextRange = textRange(from: endOfDocument, to: beginningOfDocument)

                if isBackSpace(), let nextResponder = superview?.superview?.superview?.superview?.viewWithTag(tag - 1) as UIResponder? {
                    nextResponder.becomeFirstResponder()
                }
            }
        case .moveToPreviousAndDelete:
            if let nextResponder = superview?.superview?.superview?.superview?.viewWithTag(tag - 1) as UIResponder? {
                nextResponder.becomeFirstResponder()
            }
        }
    }
}
