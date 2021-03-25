//
//  ViewController.swift
//  Chapter19-3
//
//  Created by daito yamashita on 2021/03/24.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate{
    
    @IBOutlet weak var shutterButton: UIButton!
    
    @IBOutlet weak var previewView: UIView!
    
    var session = AVCaptureSession()
    var photoOutputObj = AVCapturePhotoOutput()
    
    let notification = NotificationCenter.default
    
    // アラートを表示
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // セッション実行中ならば中断する
        guard !session.isRunning else {
            return
        }
        
        // シャッターボタンを有効にする
        shutterButton.isEnabled = true
        
        // 入出力の設定
        setupInputOutput()
        
        // プレビューレイヤの設定
        setPreviewLayer()
        
        // セッション開始
        session.startRunning()
        
        // デバイスが回転した時に通知するイベントハンドラを設定する
        notification.addObserver(
            self,
            selector: #selector(self.changedDeviceOrientation(_ :)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
    }
    
    // シャッターボタン
    @IBAction func takePhoto(_ sender: Any) {
        // キャプチャのセッティング
        let captureSetting = AVCapturePhotoSettings()
        captureSetting.flashMode = .auto
        captureSetting.isAutoStillImageStabilizationEnabled = true
        captureSetting.isHighResolutionPhotoEnabled = false
        
        // キャプチャのイメージ処理をdelegate
        photoOutputObj.capturePhoto(with: captureSetting, delegate: self)
    }
    
    func setupInputOutput() {
        // 解像度の指定
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        // 入力の設定
        do {
            let device = AVCaptureDevice.default(
                AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                for: AVMediaType.video,
                position: AVCaptureDevice.Position.back)
            
            // 入力元
            let input = try AVCaptureDeviceInput(device: device!)
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("セッションに追加できなかった")
                return
            }
        }
        catch let error as NSError {
            print("カメラが使えない \n \(error.description)")
            // カメラのプライバシー設定を開くためのアラートを表示する
            showAlert(appName: "カメラ")
            return
        }
        
        // 出力の設定
        if session.canAddOutput(photoOutputObj) {
            session.addOutput(photoOutputObj)
        } else {
            print("セッションに出力を追加できなかった")
            return
        }
    }
    
    func showAlert(appName: String) {
        let aTitle = appName + "のプライバシー認証"
        let aMessage = "設定＞プライバシー＞" + appName + "で利用してください"
        let alert = UIAlertController(
            title: aTitle,
            message: aMessage,
            preferredStyle: .alert
        )
        
        // 許可しないボタン（シャッターボタンを利用できなくする）
        alert.addAction(
            UIAlertAction(
                title: "許可しない",
                style: .default,
                handler: { action in
                    self.shutterButton.isEnabled = false
                }
            )
        )
        
        // 設定を開くボタン
        alert.addAction(
            UIAlertAction(
                title: "設定を開く",
                style: .default,
                handler: { action in
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!,
                        options: [:],
                        completionHandler: nil
                    )
                }
            )
        )
        
        // アラートを表示する
        self.present(alert, animated: false, completion: nil)
    }
    
    // プレビューレイヤの設定
    func setPreviewLayer() {
        // プレビューレイヤを作る
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.masksToBounds = true
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        // previewに追加する
        previewView.layer.addSublayer(previewLayer)
    }
    
    @objc func changedDeviceOrientation(_ notification: Notification) {
        // PhotoOutputObj.connectionの回転向きをデバイスと合わせる
        if let photoOutputConnection = self.photoOutputObj.connection(with: AVMediaType.video) {
            switch UIDevice.current.orientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else {
            return
        }
        
        if let stillImage = UIImage(data: photoData) {
            // アルバムに追加する
            UIImageWriteToSavedPhotosAlbum(
                stillImage,
                self,
                #selector(image(_ :didFinishSavingWithError: contextInfo: )),
                nil
            )
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(
                title: "アルバムへの追加エラー",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default
                )
            )
            present(alert, animated: true)
        } else {
            print("アルバムへの追加　OK")
        }
    }
}
