#!/usr/bin/env swift

import Foundation
import UIKit
import SwiftUI

print("===== FONT DEBUGGING TOOL =====")
print("Searching for available fonts...")
print("")

let families = UIFont.familyNames.sorted()
var cooperFontsFound = false

print("=== ALL FONT FAMILIES ===")
for family in families {
    print("• \(family)")
    let fontNames = UIFont.fontNames(forFamilyName: family)
    for name in fontNames {
        print("   - \(name)")
        if name.lowercased().contains("cooper") {
            cooperFontsFound = true
        }
    }
}

print("\n=== COOPER FONTS SEARCH ===")
if !cooperFontsFound {
    print("❌ No Cooper fonts found in the system")
    print("You need to:")
    print("1. Install Cooper Black via Adobe Fonts, or")
    print("2. Bundle the font with your app")
} else {
    print("✅ Cooper fonts found! These are the matches:")
    for family in families {
        let fontNames = UIFont.fontNames(forFamilyName: family)
        for name in fontNames {
            if name.lowercased().contains("cooper") {
                print("• \(name) (Family: \(family))")
            }
        }
    }
}

print("\n=== RECOMMENDATIONS ===")
print("1. Update FontExtensions.swift with the exact font name")
print("2. If no Cooper fonts are found, activate it in Adobe Fonts")
print("3. Or bundle Cooper Black with your app (see include_cooper_black_font.md)") 