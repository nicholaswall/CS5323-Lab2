//
//  PartBViewController.swift
//  AudioLabSwift
//
//  Created by Nick Wall on 10/5/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit

let PART_B_AUDIO_BUFFER_SIZE = 1024 * 4;

class PartBViewController: UIViewController {

    @IBOutlet weak var fftMagnitudeLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencySlider: UISlider!
    @IBAction func sliderFrequencyChanged(_ sender: UISlider) {
        frequency = Int(sender.value)
        self.frequencyLabel.text = "Frequency: \(frequency)Hz"
        self.audio.startProcessingSinewaveForPlayback(withFreq: Float(frequency))
        
    }
    
    let audio = PartBAudioModel(buffer_size: PART_B_AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    var frequency = 20000;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.frequencyLabel.text = "Frequency: \(self.frequency)Hz"
        frequencySlider.minimumValue = 15000;
        frequencySlider.maximumValue = 20000;
        frequencySlider.setValue(Float(frequency), animated: true)
        
        frequencyLabel.textColor = UIColor.white
        fftMagnitudeLabel.textColor = UIColor.white
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: PART_B_AUDIO_BUFFER_SIZE/2)
        
        audio.startMicrophoneProcessing(withFps: 20)
        audio.startProcessingSinewaveForPlayback(withFreq: Float(frequency))
        audio.play()
        
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateLabel),
            userInfo: nil,
            repeats: true)
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @objc
    func updateLabel(){
        self.graph?.updateGraph(
                    data: self.audio.fftData,
                    forKey: "fft"
                )
        
        // ASK IN CLASS IS THIS RIGHT?
        self.fftMagnitudeLabel.text = "FFT Magnitude: \(self.audio.getVolume())dB"
        
    }

}
