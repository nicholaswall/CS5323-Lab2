//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    var timeData:[Float]
    var fftData:[Float]
    
    var nLargestValues: [Float] = Array.init(repeating: 0.0, count: 2)
    
    var enableMaxCalculation = true;
    
    let serialQueue = DispatchQueue(label: "fftMaxQueue")
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        
        nLargestValues = Array.init(repeating: 0.0, count: 2)
        
        
        
        self.audioManager?.outputBlock = nil
        self.audioManager?.samplingRate = 44100
        
        print("AM INIT")
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        
        print("SMP")
        self.audioManager?.inputBlock = self.handleMicrophone
        
        // repeat this fps times per second using the timer class
        Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                            selector: #selector(self.runEveryInterval),
                            userInfo: nil,
                            repeats: true)
        
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.getMaxes), userInfo: nil, repeats: true)
    }
    

    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        self.audioManager?.play()
    }
    
    func toggleMaxCalculation() {
        self.enableMaxCalculation = !self.enableMaxCalculation
    }
    
    
    // for sliding max windows, you might be interested in the following: vDSP_vswmax
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
//    private lazy var outputBuffer:CircularBuffer? = {
//        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numOutputChannels),
//                                   andBufferSize: Int64(BUFFER_SIZE))
//    }()
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    
    //==========================================
    // MARK: Model Callback Methods
    @objc
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy data to swift array
            self.inputBuffer!.fetchFreshData(&timeData, withNumSamples: Int64(BUFFER_SIZE))

            // now take FFT and display it
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)


        }
    }
    
   
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        
        
        // Very strange issue, on iPhone 11 pro this crashes instantly because the numFrames = 940
        // Error: Couldn't render the output unit (-50)
        // https://github.com/alexbw/novocaine/issues/27
        // While on the iPhone 11 pro simulator the numFrames = 470
        
        // Check Novicane.m line 471 to see the issue
        
        
//        var max:Float = 0.0
//        if let arrayData = data{
//            for i in 0..<Int(numFrames){
//                if(abs(arrayData[i])>max){
//                    max = abs(arrayData[i])
//                }
//            }
//        }
//        // can this max operation be made faster??
//        print(max)
        
//        print("NUM FRAMES: \(numFrames)")
        
        // co py samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
        
//        print("WORKS HERE...")
    }
    
    // To get the true max hz we take K (the index of the timeValues) and multiply it by Fs/N where
    // Fs is the true sampling rate (we only use half so it should be around 48000) divided by the N
    // which is the size of the time array
    
    // We cannot just take 2 global maxes because the second largest will always be right next to the largest
    // instead we need to find local maxes using a peak finding algorithm
    // To do this we take a maximum in a small window. We keep moving the window by 1 and if the max
    // value in the window is in the center then we know we have found the for that peak. We save the max
    // in this case to another array. After sweeping the whole fft, then we take the 2 largest values from
    // the max array.
    
    //TODO: need to determine window and buffer size based on fft math and hz ranges allowed for assignment
    
    @objc
    public func getMaxes() {
        
        if(self.enableMaxCalculation == false) {
            return;
        }
        
        serialQueue.async {
            var maxes: [Float] = Array.init();
            let windowSize: Int = 50;
            
//            print("FFT: \(self.fftData)")

            // Move window across the fft by 1 each step.
            let numWindows = Int(self.fftData.count - Int(windowSize));
            for i in 0..<numWindows{
                var windowMax: Float = 0.0;
                var windowCount: Int = 0;
                
                for j in 0..<Int(windowSize) {
                    let currentIndex = j + i;
                    // Must check for array bounds
                    if (currentIndex < self.fftData.count) {
                        // Not sure why but all values are negative
                        let currentVal = abs(self.fftData[currentIndex])
                        if(currentVal > windowMax) {
                            windowMax = currentVal;
                        }
                        windowCount = windowCount + 1;
                    }
                }
                // Now we check to see if the max from the window was the middle value of the array
                let midIndex = (windowSize / 2) + i;
                if windowMax == abs(self.fftData[midIndex]) {
                    // TO get the real hz value we need to multiply k * (Fs / N)
                    let hz = Float(midIndex) * (windowMax / Float(self.BUFFER_SIZE))
                    print("LARGEST Window FREQUENCY: \(hz)")
                    maxes.append(hz);
                }
            }
            maxes.sort()
            if(maxes.count >= 2) {
                self.nLargestValues[1] = maxes[maxes.count - 1];
                self.nLargestValues[0] = maxes[maxes.count - 2];
            }
        }
    }
}
