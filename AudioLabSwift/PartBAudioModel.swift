//
//  PartBAudioModel.swift
//  AudioLabSwift
//
//  Created by Nick Wall on 10/5/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import Foundation

class PartBAudioModel {
    
    private var BUFFER_SIZE: Int;
    var timeData:[Float]
    var fftData:[Float]
    
    let USE_C_SINE = true;
    
    
    
    init(buffer_size: Int) {
        self.BUFFER_SIZE = buffer_size;
        
        timeData = Array.init(repeating: 0.0, count: self.BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: self.BUFFER_SIZE/2)

    }
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        sineFrequency = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        if let manager = self.audioManager{
            
            if USE_C_SINE {
                // c for loop
                manager.setOutputBlockToPlaySineWave(sineFrequency)
            }else{
                // swift for loop
                manager.outputBlock = self.handleSpeakerQueryWithSinusoid
            }
            
            
        }
    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    //==========================================
    // MARK: Model Callback Methods
   
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    
    //    _     _     _     _     _     _     _     _     _     _
    //   / \   / \   / \   / \   / \   / \   / \   / \   / \   /
    //  /   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            
            if let manager = self.audioManager {
                if USE_C_SINE {
                    // if using objective c: this changes the frequency in the novocaine block
                    manager.sineFrequency = sineFrequency
                    
                }else{
                    // if using swift for generating the sine wave: when changed, we need to update our increment
                    phaseIncrement = Float(2*Double.pi*Double(sineFrequency)/manager.samplingRate)
                }
            }
        }
    }
    
    // SWIFT SINE WAVE
    // everything below here is for the swift implementation
    // this can be deleted when using the objective c implementation
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    private func handleSpeakerQueryWithSinusoid(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        // while pretty fast, this loop is still not quite as fast as
        // writing the code in c, so I placed a function in Novocaine to do it for you
        // use setOutputBlockToPlaySineWave() in Novocaine
        if let arrayData = data{
            var i = 0
            while i<numFrames{
                arrayData[i] = sin(phase)
                phase += phaseIncrement
                if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                i+=1
            }
        }
    }
    
    func startMicrophoneProcessing(withFps:Double){
        
        self.audioManager?.inputBlock = self.handleMicrophone
        
        // repeat this fps times per second using the timer class
        Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                            selector: #selector(self.runEveryInterval),
                            userInfo: nil,
                            repeats: true)
        
    }
    
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        
        
        // Very strange issue, on iPhone 11 pro this crashes instantly because the numFrames = 940
        // Error: Couldn't render the output unit (-50)
        // https://github.com/alexbw/novocaine/issues/27
        // While on the iPhone 11 pro simulator the numFrames = 470
        
        // Check Novicane.m line 471 to see the issue
        
        // co py samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
        
    }
    
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
    
    func getVolume() -> Float{
        // Is this the correct idea?
        let mag = vDSP.maximumMagnitude(self.fftData)
        let volume = 10 * log10(mag)
        return volume;
    }
}
