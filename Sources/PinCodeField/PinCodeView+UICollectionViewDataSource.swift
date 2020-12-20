//
//  PinCodeField+UICollectionViewDataSource.swift
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

extension PinCodeView: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pinLength
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        guard let textField = cell.viewWithTag(100) as? PinCodeItem,
              let containerView = cell.viewWithTag(51),
              let underLine = cell.viewWithTag(50),
              let placeholderLabel = cell.viewWithTag(400) as? UILabel
        else {
            showPinError(error: "ERR-104: Tag Mismatch")
            return UICollectionViewCell()
        }

        // Setting up textField
        textField.tag = 101 + indexPath.row
        textField.isSecureTextEntry = false
        textField.textColor = self.textColor
        textField.tintColor = self.tintColor
        textField.font = self.font
        textField.deleteButtonAction = self.deleteButtonAction
        if #available(iOS 12.0, *), indexPath.row == 0, isContentTypeOneTimeCode {
            textField.textContentType = .oneTimeCode
        }
        textField.keyboardType = self.keyboardType
        textField.keyboardAppearance = self.keyboardAppearance
        textField.inputAccessoryView = self.pinInputAccessoryView

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        placeholderLabel.text = ""
        placeholderLabel.textColor = self.textColor.withAlphaComponent(0.5)

        stylePinField(containerView: containerView, underLine: underLine, isActive: false)

        // Make the Pin field the first responder
        if let firstResponderIndex = becomeFirstResponderAtIndex, firstResponderIndex == indexPath.item {
            textField.becomeFirstResponder()
        }

        // Finished loading pinView
        if indexPath.row == pinLength - 1 && isLoading {
            isLoading = false
            DispatchQueue.main.async {
                if !self.placeholder.isEmpty { self.setPlaceholder() }
            }
        }

        return cell
    }
}
