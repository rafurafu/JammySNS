//
//  CameraModel.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/11/08.
//

import SwiftUI

enum ImagePickerSource {
    case camera
    case photoLibrary
}

struct ActionSheetOption {
    let title: String
    let action: () -> Void
}
