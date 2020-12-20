//
//  PinCodeField+UITextFieldDelegate.swift
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

extension PinCodeView: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        let text = textField.text ?? ""
        if let placeholderLabel = textField.superview?.viewWithTag(400) as? UILabel {
            placeholderLabel.isHidden = true

            if text.count == 0 {
                textField.isSecureTextEntry = false
                placeholderLabel.isHidden = false
            } else if deleteButtonAction == .moveToPreviousAndDelete {
                textField.text = ""
                let passwordIndex = (textField.tag - 100) - 1
                if password.count > (passwordIndex) {
                    password[passwordIndex] = ""
                    textField.isSecureTextEntry = false
                    placeholderLabel.isHidden = false
                }
            }
        } else { showPinError(error: "ERR-105: Type Mismatch") }

        if let containerView = textField.superview?.viewWithTag(51),
           let underLine = textField.superview?.viewWithTag(50) {
            self.stylePinField(containerView: containerView, underLine: underLine, isActive: true)
        } else { showPinError(error: "ERR-106: Type Mismatch") }
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        if let containerView = textField.superview?.viewWithTag(51),
           let underLine = textField.superview?.viewWithTag(50) {
            self.stylePinField(containerView: containerView, underLine: underLine, isActive: false)
        } else { showPinError(error: "ERR-107: Type Mismatch") }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string.count >= pinLength) && (string == UIPasteboard.general.string || isContentTypeOneTimeCode) {
            textField.resignFirstResponder()
            DispatchQueue.main.async { self.pastePin(pin: string) }
            return false
        } else if let cursorLocation = textField.position(from: textField.beginningOfDocument, offset: (range.location + string.count)),
                  cursorLocation == textField.endOfDocument {
            // If the user moves the cursor to the beginning of the field, move it to the end before textEntry,
            // so the oldest digit is removed in textFieldDidChange: to ensure single character entry
            textField.selectedTextRange = textField.textRange(from: cursorLocation, to: textField.beginningOfDocument)
        }
        return true
    }
}
