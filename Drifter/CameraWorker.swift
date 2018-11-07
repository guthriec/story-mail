
//
//  CameraWorker.swift
//  Drifter
//
//  Created by Chris on 8/31/18.
//  Copyright © 2018 Sun Canyon. All rights reserved.
//
//  Thanks to https://www.appcoda.com/avfoundation-swift-guide/

import Foundation
import AVFoundation
import UIKit

class CameraWorker: NSObject {
  var captureSession: AVCaptureSession?
  var frontCamera: AVCaptureDevice?
  var rearCamera: AVCaptureDevice?
  
  var currentCameraPosition: CameraPosition?
  var frontCameraInput: AVCaptureDeviceInput?
  var rearCameraInput: AVCaptureDeviceInput?
  
  var photoOutput: AVCapturePhotoOutput?
  var photoCaptureCompletionHandler: ((UIImage?, Error?) -> Void)?
  
  var previewLayer: AVCaptureVideoPreviewLayer?
  
  var flashMode = AVCaptureDevice.FlashMode.off
  
  func prepare(completionHandler: @escaping (Error?) -> Void) {
    func createCaptureSession() {
      self.captureSession = AVCaptureSession()
    }
    
    func configureCaptureDevices() throws {
      let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                     mediaType: AVMediaType.video,
                                                     position: .unspecified)
      let cameras = (session.devices.compactMap { $0 })
      if cameras.isEmpty {
        throw CameraWorkerError.noCamerasAvailable
      }
      for camera in cameras {
        if camera.position == .front {
          self.frontCamera = camera
        }
        if camera.position == .back {
          self.rearCamera = camera
          try camera.lockForConfiguration()
          camera.focusMode = .continuousAutoFocus
          camera.unlockForConfiguration()
        }
      }
    }
    
    func configureDeviceInputs() throws {
      guard let captureSession = self.captureSession else {
        throw CameraWorkerError.captureSessionIsMissing
      }
      if let rearCamera = self.rearCamera {
        self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        if captureSession.canAddInput(self.rearCameraInput!) {
          captureSession.addInput(self.rearCameraInput!)
        }
        self.currentCameraPosition = .rear
      }
      else if let frontCamera = self.frontCamera {
        self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        if captureSession.canAddInput(self.frontCameraInput!) {
          captureSession.addInput(self.frontCameraInput!)
        }
        self.currentCameraPosition = .front
      }
      else {
        throw CameraWorkerError.noCamerasAvailable
      }
    }
    
    func configurePhotoOutput() throws {
      guard let captureSession = self.captureSession else {
        throw CameraWorkerError.captureSessionIsMissing
      }
      self.photoOutput = AVCapturePhotoOutput()
      self.photoOutput!.setPreparedPhotoSettingsArray(
        [AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])],
        completionHandler: nil)
      if captureSession.canAddOutput(self.photoOutput!) {
        captureSession.addOutput(self.photoOutput!)
      }
      captureSession.startRunning()
    }
    
    DispatchQueue(label: "prepare").async {
      do {
        createCaptureSession()
        try configureCaptureDevices()
        try configureDeviceInputs()
        try configurePhotoOutput()
      }
      catch {
        DispatchQueue.main.async {
          completionHandler(error)
        }
        return
      }
      DispatchQueue.main.async {
        completionHandler(nil)
      }
    }
  }
  
  func displayPreview(insideOf view: UIView) throws {
    guard let captureSession = self.captureSession, captureSession.isRunning else {
      throw CameraWorkerError.captureSessionIsMissing
    }
    self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
    self.previewLayer?.connection?.videoOrientation = .portrait
    
    self.previewLayer?.frame = view.bounds
    view.layer.insertSublayer(self.previewLayer!, at: 0)
  }
  
  func switchCameras() throws {
    guard let currentCameraPosition = self.currentCameraPosition,
          let captureSession = self.captureSession,
          captureSession.isRunning else {
        throw CameraWorkerError.captureSessionIsMissing
    }
    var newCameraPosition: CameraPosition?
    var currentCameraInput: AVCaptureDeviceInput?
    var newCameraInput: AVCaptureDeviceInput?
    
    if currentCameraPosition == .front {
      currentCameraInput = self.frontCameraInput
      newCameraPosition = .rear
      guard let newCameraDevice = self.rearCamera else {
        print("failed to switch from front to back")
        throw CameraWorkerError.invalidOperation
      }
      self.rearCameraInput = try AVCaptureDeviceInput(device: newCameraDevice)
      newCameraInput = self.rearCameraInput
    } else if currentCameraPosition == .rear {
      currentCameraInput = self.rearCameraInput
      newCameraPosition = .front
      guard let newCameraDevice = self.frontCamera else {
        print ("failed to switch from back to front")
        throw CameraWorkerError.invalidOperation
      }
      self.frontCameraInput = try AVCaptureDeviceInput(device: newCameraDevice)
      newCameraInput = self.frontCameraInput
    }
    
    // Reconfigure capture session to switch cameras
    
    captureSession.beginConfiguration()
    
    guard let oldCameraInput = currentCameraInput,
        let cameraInput = newCameraInput,
        captureSession.inputs.contains(oldCameraInput) else {
      throw CameraWorkerError.inputsAreInvalid
    }
    captureSession.removeInput(oldCameraInput)
    if captureSession.canAddInput(cameraInput) {
      captureSession.addInput(cameraInput)
      self.currentCameraPosition = newCameraPosition
    } else {
      print("failed to reconfigure capture session")
      throw CameraWorkerError.invalidOperation
    }
    
    captureSession.commitConfiguration()
  }
  
  func captureImage(completionHandler: @escaping (UIImage?, Error?) -> Void) {
    guard let captureSession = self.captureSession else {
      completionHandler(nil, CameraWorkerError.captureSessionIsMissing)
      return
    }
    if !captureSession.isRunning {
      completionHandler(nil, CameraWorkerError.unknown)
    }
    let settings = AVCapturePhotoSettings()
    settings.flashMode = self.flashMode
    self.photoOutput?.capturePhoto(with: settings, delegate: self)
    self.photoCaptureCompletionHandler = completionHandler
  }
}

extension CameraWorker : AVCapturePhotoCaptureDelegate {
  func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    if let error = error {
      self.photoCaptureCompletionHandler?(nil, error)
    }
    guard let buffer = photoSampleBuffer else {
      self.photoCaptureCompletionHandler?(nil, CameraWorkerError.unknown)
      print("1")
      return
    }
    guard let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer,
                                                                      previewPhotoSampleBuffer: nil)
    else {
      self.photoCaptureCompletionHandler?(nil, CameraWorkerError.unknown)
      return
    }
    guard let image = UIImage(data: data) else {
      self.photoCaptureCompletionHandler?(nil, CameraWorkerError.unknown)
      return
    }
    if self.currentCameraPosition == CameraPosition.front {
      guard let cgImage = image.cgImage else {
        self.photoCaptureCompletionHandler?(nil, CameraWorkerError.unknown)
        return
      }
      self.photoCaptureCompletionHandler?(UIImage(cgImage: cgImage, scale: 1.0,
                                                  orientation: UIImage.Orientation.leftMirrored),
                                          nil)
    } else {
      self.photoCaptureCompletionHandler?(image, nil)
    }
  }
}

enum CameraWorkerError: Swift.Error {
  case captureSessionAlreadyRunning
  case captureSessionIsMissing
  case inputsAreInvalid
  case invalidOperation
  case noCamerasAvailable
  case unknown
}

public enum CameraPosition {
  case front
  case rear
}
