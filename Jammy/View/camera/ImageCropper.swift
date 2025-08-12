//
//  SwiftUIView.swift
//  Jammy
//
//  Created by 柳井大輔 on 2024/11/08.
//
import SwiftUI
import CropViewController

struct ImageCropper: UIViewControllerRepresentable {
    let image: UIImage
    @Binding var visible: Bool
    var done: (UIImage) -> Void
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        let parent: ImageCropper
        
        init(_ parent: ImageCropper) {
            self.parent = parent
        }
        
        // 編集完了時の処理
        func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            parent.done(image)
            parent.visible = false
        }
        
        // キャンセル時の処理
        func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
            parent.visible = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CropViewController {
        let cropViewController = CropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.aspectRatioPreset = .presetSquare
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.rotateButtonsHidden = false
        cropViewController.cropView.cropBoxResizeEnabled = true
        return cropViewController
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        // 更新が必要な場合の処理
    }
}
