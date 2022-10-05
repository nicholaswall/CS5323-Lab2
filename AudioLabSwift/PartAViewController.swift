//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal


let AUDIO_BUFFER_SIZE = 1024*4
//let AUDIO_BUFFER_SIZE = 1200 * 4


class PartAViewController: UIViewController {

    
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
//    lazy var graph:MetalGraph? = {
//        return MetalGraph(mainView: self.graphView)
//    }()
    

    
    @IBAction func toggleMaxesPressed(_ sender: UIButton) {
        self.audio.toggleMaxCalculation()
    }
    @IBOutlet weak var maxesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // add in graphs for display
//        graph?.addGraph(withName: "fft",
//                        shouldNormalize: true,
//                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
//
//        graph?.addGraph(withName: "time",
//            shouldNormalize: false,
//            numPointsInGraph: AUDIO_BUFFER_SIZE)
        
        // just start up the audio model here
        audio.startMicrophoneProcessing(withFps: 10)
        //audio.startProcesingAudioFileForPlayback()
//        audio.startProcessingSinewaveForPlayback(withFreq: 630.0)
        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateLabel),
            userInfo: nil,
            repeats: true)
       
    }
    
    
    @objc
    func updateLabel(){
        
//        if(self.toggle == false) {
//                DispatchQueue.main.asyncAfter(deadline: .now()) {
//                    // Put your code which should be executed with a delay here
//                    self.audio.getMaxes()
//                    self.maxesLabel.text = "Maxes: \(self.audio.nLargestValues[0]), \(self.audio.nLargestValues[1])"
//                }
//
//
//        }
        self.maxesLabel.text = "Maxes: \(self.audio.nLargestValues[0]), \(self.audio.nLargestValues[1])"
        
    }
    
    

}

