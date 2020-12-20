//
//  PinCodeField.swift
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

@objc
public enum PinCodeViewStyle: Int {
    case none = 0
    case underline
    case box
}

@objc
public enum PinCodeViewDeleteButtonAction: Int {
    /// Deletes the contents of the current field and moves the cursor to the previous field.
    case deleteCurrentAndMoveToPrevious = 0
    
    /// Simply deletes the content of the current field without moving the cursor.
    /// If there is no value in the field, the cursor moves to the previous field.
    case deleteCurrent
    
    /// Moves the cursor to the previous field and delets the contents.
    /// When any field is focused, its contents are deleted.
    case moveToPreviousAndDelete
}

private class PinCodeViewFlowLayout: UICollectionViewFlowLayout {
    override var developmentLayoutDirection: UIUserInterfaceLayoutDirection { return .leftToRight }
    override var flipsHorizontallyInOppositeLayoutDirection: Bool { return true }
}

@objcMembers
public class PinCodeView: UIView {
    
    // MARK: - Private Properties -
    @IBOutlet internal var collectionView: UICollectionView!
    @IBOutlet internal var errorView: UIView!
    
    internal var flowLayout: UICollectionViewFlowLayout {
        self.collectionView.collectionViewLayout = PinCodeViewFlowLayout()
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    internal var view: UIView!
    internal var reuseIdentifier = "PinCodeCell"
    internal var isLoading = true
    internal var password = [String]()
    
    // MARK: - Public Properties -
    @IBInspectable public var pinLength: Int = 5
    @IBInspectable public var secureCharacter: String = "\u{25CF}"
    @IBInspectable public var interSpace: CGFloat = 5
    @IBInspectable public var textColor: UIColor = UIColor.black
    @IBInspectable public var shouldSecureText: Bool = true
    @IBInspectable public var secureTextDelay: Int = 500
    @IBInspectable public var allowsWhitespaces: Bool = true
    @IBInspectable public var placeholder: String = ""
    
    @IBInspectable public var borderLineColor: UIColor = UIColor.black
    @IBInspectable public var activeBorderLineColor: UIColor = UIColor.black
    
    @IBInspectable public var borderLineThickness: CGFloat = 2
    @IBInspectable public var activeBorderLineThickness: CGFloat = 4
    
    @IBInspectable public var fieldBackgroundColor: UIColor = UIColor.clear
    @IBInspectable public var activeFieldBackgroundColor: UIColor = UIColor.clear
    
    @IBInspectable public var fieldCornerRadius: CGFloat = 0
    @IBInspectable public var activeFieldCornerRadius: CGFloat = 0
    
    public var style: PinCodeViewStyle = .underline
    public var deleteButtonAction: PinCodeViewDeleteButtonAction = .deleteCurrentAndMoveToPrevious
    
    public var font: UIFont = UIFont.systemFont(ofSize: 15)
    public var keyboardType: UIKeyboardType = UIKeyboardType.phonePad
    public var keyboardAppearance: UIKeyboardAppearance = .default
    public var becomeFirstResponderAtIndex: Int? = nil
    public var isContentTypeOneTimeCode: Bool = true
    public var shouldDismissKeyboardOnEmptyFirstField: Bool = false
    public var pinInputAccessoryView: UIView? {
        didSet { refreshPinView() }
    }
    
    public var didFinishCallback: ((String)->())?
    public var didChangeCallback: ((String)->())?
    
    // MARK: - Init methods -
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }
    
    private func loadView(completionHandler: (()->())? = nil) {
        let bundle = Bundle.module
        let nib = UINib(nibName: "PinCodeView", bundle: bundle)
        view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        
        // for CollectionView
        let collectionViewNib = UINib(nibName: "PinCodeCell", bundle: bundle)
        collectionView.register(collectionViewNib, forCellWithReuseIdentifier: reuseIdentifier)
        flowLayout.scrollDirection = .vertical
        collectionView.isScrollEnabled = false
                
        self.addSubview(view)
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completionHandler?()
        }
    }
    
    // MARK: - Private methods -
    @objc internal func textFieldDidChange(_ textField: UITextField) {
        var nextTag = textField.tag
        let index = nextTag - 100
        guard let placeholderLabel = textField.superview?.viewWithTag(400) as? UILabel else {
            showPinError(error: "ERR-101: Type Mismatch")
            return
        }
        
        // ensure single character in text box and trim spaces
        if textField.text?.count ?? 0 > 1 {
            textField.text?.removeFirst()
            textField.text = { () -> String in
                let text = textField.text ?? ""
                return String(text[..<text.index((text.startIndex), offsetBy: 1)])
            }()
        }
        
        let isBackSpace = { () -> Bool in
            guard let char = textField.text?.cString(using: String.Encoding.utf8) else { return false }
            return strcmp(char, "\\b") == -92
        }
        
        if !self.allowsWhitespaces && !isBackSpace() && textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            return
        }
        
        // if entered text is a backspace - do nothing; else - move to next field
        // backspace logic handled in PinCodeField
        nextTag = isBackSpace() ? textField.tag : textField.tag + 1
        
        // Try to find next responder
        if let nextResponder = textField.superview?.superview?.superview?.superview?.viewWithTag(nextTag) as UIResponder? {
            // Found next responder, so set it.
            nextResponder.becomeFirstResponder()
        } else {
            // Not found, so dismiss keyboard
            if index == 1 && shouldDismissKeyboardOnEmptyFirstField {
                textField.resignFirstResponder()
            } else if index > 1 { textField.resignFirstResponder() }
        }
        
        // activate the placeholder if textField empty
        placeholderLabel.isHidden = !(textField.text?.isEmpty ?? true)
        
        // secure text after a bit
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(secureTextDelay), execute: {
            if !(textField.text?.isEmpty ?? true) {
                placeholderLabel.isHidden = true
                if self.shouldSecureText { textField.text = self.secureCharacter }
            }
        })
        
        // store text
        let text =  textField.text ?? ""
        let passwordIndex = index - 1
        if password.count > (passwordIndex) {
            // delete if space
            password[passwordIndex] = text
        } else {
            password.append(text)
        }
        validateAndSendCallback()
    }
    
    internal func validateAndSendCallback() {
        didChangeCallback?(password.joined())
        
        let pin = getPin()
        guard !pin.isEmpty else { return }
        didFinishCallback?(pin)
    }
    
    internal func setPlaceholder() {
        for (index, char) in placeholder.enumerated() {
            guard index < pinLength else { return }
            
            if let placeholderLabel = collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.viewWithTag(400) as? UILabel {
                placeholderLabel.text = String(char)
            } else { showPinError(error: "ERR-102: Type Mismatch") }
        }
    }
    
    internal func stylePinField(containerView: UIView, underLine: UIView, isActive: Bool) {
        
        containerView.backgroundColor = isActive ? activeFieldBackgroundColor : fieldBackgroundColor
        containerView.layer.cornerRadius = isActive ? activeFieldCornerRadius : fieldCornerRadius
        
        func setupUnderline(color:UIColor, withThickness thickness:CGFloat) {
            underLine.backgroundColor = color
            underLine.constraints.filter { ($0.identifier == "underlineHeight") }.first?.constant = thickness
        }
        
        switch style {
        case .none:
            setupUnderline(color: UIColor.clear, withThickness: 0)
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
        case .underline:
            if isActive { setupUnderline(color: activeBorderLineColor, withThickness: activeBorderLineThickness) }
            else { setupUnderline(color: borderLineColor, withThickness: borderLineThickness) }
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
        case .box:
            setupUnderline(color: UIColor.clear, withThickness: 0)
            containerView.layer.borderWidth = isActive ? activeBorderLineThickness : borderLineThickness
            containerView.layer.borderColor = isActive ? activeBorderLineColor.cgColor : borderLineColor.cgColor
        }
     }
    
    @IBAction internal func refreshPinView(completionHandler: (()->())? = nil) {
        view.removeFromSuperview()
        view = nil
        isLoading = true
        errorView.isHidden = true
        loadView(completionHandler: completionHandler)
    }
    
    internal func showPinError(error: String) {
        errorView.isHidden = false
        print("\n----------PinCodeView Error----------")
        print(error)
        print("-----------------------------------")
    }
    
    // MARK: - Public methods -
    
    /// Returns the entered PIN; returns empty string if incomplete
    /// - Returns: The entered PIN.
    @objc
    public func getPin() -> String {
        
        guard !isLoading else { return "" }
        guard password.count == pinLength && password.joined().trimmingCharacters(in: CharacterSet(charactersIn: " ")).count == pinLength else {
            return ""
        }
        return password.joined()
    }
        
    /// Clears the entered PIN and refreshes the view
    /// - Parameter completionHandler: Called after the pin is cleared the view is re-rendered.
    @objc
    public func clearPin(completionHandler: (()->())? = nil) {
        
        guard !isLoading else { return }
        
        password.removeAll()
        refreshPinView(completionHandler: completionHandler)
    }
    
    /// Clears the entered PIN and refreshes the view.
    /// (internally calls the clearPin method; re-declared since the name is more intuitive)
    /// - Parameter completionHandler: Called after the pin is cleared the view is re-rendered.
    @objc
    public func refreshView(completionHandler: (()->())? = nil) {
        clearPin(completionHandler: completionHandler)
    }
    
    /// Pastes the PIN onto the PinView
    /// - Parameter pin: The pin which is to be entered onto the PinView.
    @objc
    public func pastePin(pin: String) {
        
        password = []
        for (index,char) in pin.enumerated() {

            guard index < pinLength else { return }

            // Get the first textField
            guard let textField = collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.viewWithTag(101 + index) as? PinCodeItem,
                let placeholderLabel = collectionView.cellForItem(at: IndexPath(item: index, section: 0))?.viewWithTag(400) as? UILabel
            else {
                showPinError(error: "ERR-103: Type Mismatch")
                return
            }

            textField.text = String(char)
            placeholderLabel.isHidden = true

            //secure text after a bit
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(secureTextDelay), execute: {
                if textField.text != "" {
                    if self.shouldSecureText { textField.text = self.secureCharacter } else {}
                }
            })

            // store text
            password.append(String(char))
            validateAndSendCallback()
        }
    }
}
