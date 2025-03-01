#!/usr/bin/env swift

import Foundation
import UIKit
import SwiftUI

print("===== FONT DEBUGGING TOOL =====")
print("Searching for available fonts...")
print("")

let families = UIFont.familyNames.sorted()
var cooperFontsFound = false

print("=== COOPER FONTS SEARCH ===")
for family in families {
    let fontNames = UIFont.fontNames(forFamilyName: family)
    for name in fontNames {
        if name.lowercased().contains("cooper") {
            cooperFontsFound = true
            print("• \(name) (Family: \(family))")
        }
    }
}

if !cooperFontsFound {
    print("❌ No Cooper fonts found in the system")
    print("You need to:")
    print("1. Make sure Creative Cloud is running")
    print("2. Ensure Cooper Std Black is activated in Adobe Fonts")
    print("3. Try restarting your system")
}

print("\n=== ADOBE FONTS CHECK ===")
let possibleCooperNames = [
    "Cooper Std Black",
    "CooperStd-Black",
    "Cooper-Black",
    "Cooper Black",
    "CooperBlack"
]

print("Testing specific Adobe font names:")
for name in possibleCooperNames {
    if let _ = UIFont(name: name, size: 12) {
        print("✅ FOUND: \(name)")
    } else {
        print("❌ NOT FOUND: \(name)")
    }
}

print("\n=== RECOMMENDATIONS ===")
print("1. Make sure Creative Cloud is running")
print("2. Use the exact PostScript name in your FontExtensions.swift")
print("3. If needed, restart your Mac to refresh the font cache")
print("4. Clean and rebuild your project in Xcode") 