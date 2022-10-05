//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal


//let AUDIO_BUFFER_SIZE = 1024*4
let AUDIO_BUFFER_SIZE = 8192
// 48000/N = BucketSize
// 6 = 48000/N
// N = 48000/6


class PartAViewController: UIViewController {

    
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    

    
    @IBAction func toggleMaxesPressed(_ sender: UIButton) {
        self.audio.toggleMaxCalculation()
    }
    
    @IBOutlet weak var maxesLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.maxesLabel.textColor = UIColor.white;
        
        
        // add in graphs for display
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
        
        // just start up the audio model here
        audio.startMicrophoneProcessing(withFps: 10)
        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateLabel),
            userInfo: nil,
            repeats: true)
       
    }
    
    
    @objc
    func updateLabel(){
        self.graph?.updateGraph(
                    data: self.audio.fftData,
                    forKey: "fft"
                )
        
        self.maxesLabel.text = "Maxes: \(self.audio.nLargestValues[0]), \(self.audio.nLargestValues[1])"
        
    }
    
    

}

