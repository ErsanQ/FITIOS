//
//  CreateWorkoutViewController.swift
//  FItios
//
//  Created by Ersan on 11/01/2022.
//

import UIKit
import CoreLocation
import CoreMotion

enum WorkoutState {
    case inactive
case active
case paused }
let timerInterval: TimeInterval = 1.0


struct WorkoutType {
    static let automotive = "Driving"
    static let running = "Running"
    static let bicycling = "Bicycling"
    static let stationary = "Stationary"
    static let walking = "Walking"
    static let unknown = "Unknown"
}


class CreateWorkoutViewController : UIViewController {
    
    
    
    
    let locationManager = CLLocationManager()
    @IBOutlet weak var workoutTimeLabel: UILabel?
       @IBOutlet weak var workoutDistanceLabel: UILabel?
    @IBOutlet weak var workoutPaceLabel: UILabel?
    
    
       @IBOutlet weak var toggleWorkoutButton: UIButton?
       @IBOutlet weak var pauseWorkoutButton: UIButton?
    
    var workoutAltitude: Double = 0.0
    var workoutDistance: Double = 0.0
    var lastSavedLocation: CLLocation?
    
    
    var averagePace: Double = 0.0
    var workoutSteps: Int = 0
    var floorsAscended: Int = 0
    
    var currentWorkoutState = WorkoutState.inactive
    var currentWorkoutType = WorkoutType.unknown
    
    
    var lastSavedTime: Date?
        var workoutDuration: TimeInterval = 0.0
         var workoutTimer: Timer?
    
    var workoutStartTime: Date?
    var pedometer: CMPedometer?
    var motionManager: CMMotionActivityManager?
    var altimeter: CMAltimeter?
    
    var isMotionAvailable: Bool = false
    
    
    override func viewDidLoad() {
          super.viewDidLoad()
        updateUserInterface()
  }
      override func didReceiveMemoryWarning() {
          super.didReceiveMemoryWarning()
  }
    @IBAction func toggleWorkout() {
        switch currentWorkoutState {
                     case .inactive:
                           currentWorkoutState = .active
                           requestLocationPermission()
                     case .active:
                           currentWorkoutState = .inactive
            pedometer?.stopUpdates()
            altimeter?.stopRelativeAltitudeUpdates()
           // WorkoutDataManager.sharedManager.saveWorkout( duration: workoutDuration)
            if let workoutStartTime = workoutStartTime {
                let workout = Workout(startTime: workoutStartTime,endTime: Date(), duration: workoutDuration,locations: [], workoutType:self.currentWorkoutType, totalSteps: Double(workoutSteps), flightsClimbed: Double(floorsAscended),distance: workoutDistance)
                       WorkoutDataManager.sharedManager.saveWorkout(workout)
                     }
            
                     default:
                           NSLog("toggleWorkout() called out of context!")
        }
           NSLog("Toggle workout button pressed")
        updateUserInterface()
   }
       @IBAction func pauseWorkout() {
           switch currentWorkoutState {
                   case .paused:
                      startWorkout()
                   case .active:
                      currentWorkoutState = .paused
                stopWorkoutTimer()
                   default:
                      NSLog("pauseWorkout() called out of context!")
          }
           NSLog("Pause workout button pressed")
           updateUserInterface()
   }
    
    func stopWorkoutTimer() {
           workoutTimer?.invalidate()
              lastSavedTime = nil
        }
    
    func resetWorkoutData() {
         lastSavedTime = Date()
         workoutDuration = 0.0
         workoutDistance = 0.0
        workoutAltitude = 0.0
        currentWorkoutType = WorkoutType.unknown
        workoutSteps = 0
         floorsAscended = 0
         averagePace = 0.0
   }
    
    
    
    
    
    func updateUserInterface() {
        switch(currentWorkoutState) {
        case .active:
            toggleWorkoutButton?.setTitle("Stop", for: UIControl.State.normal)
            pauseWorkoutButton?.setTitle("Pause", for: UIControl.State.normal)
            pauseWorkoutButton?.isHidden = false
        case .paused:
            pauseWorkoutButton?.setTitle("Resume", for: UIControl.State.normal)
             pauseWorkoutButton?.isHidden = false
        default:
            toggleWorkoutButton?.setTitle("Start", for: UIControl.State.normal)
    
            pauseWorkoutButton?.setTitle("Pause", for: UIControl.State.normal)
            pauseWorkoutButton?.isHidden = true
            }
        
    }
    
    
    func requestLocationPermission() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 10.0 //meters
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.delegate = self
            
            switch(CLLocationManager.authorizationStatus()) {
                         case .notDetermined:
                           locationManager.requestWhenInUseAuthorization()
                         case .authorizedWhenInUse :
                           requestAlwaysPermission()
                         case .authorizedAlways:
                           startWorkout()
                           resetWorkoutData()
                         default:
                           presentPermissionErrorAlert()
            }
            
                    NSLog("Location services are available")
                } else {
                    presentEnableLocationAlert()
        }
            NSLog("Location permission requested")
   }
    
    
    
    
    
    func presentEnableLocationAlert() {
        let alert = UIAlertController(title: "Permission Error", message: "Please enable location services on your device", preferredStyle: UIAlertController.Style.alert)
           let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
           alert.addAction(okAction)
           self.present(alert, animated: true, completion: nil)
   }
    
    
    
    func requestAlwaysPermission() {
         if let isConfigured = UserDefaults.standard.value(forKey:
           "isConfigured") as? Bool, isConfigured == true {
                startWorkout()
   
           } else {
               locationManager.requestAlwaysAuthorization()
   } }
    
    
    
    
       func startWorkout() {
           currentWorkoutState = .active
           UserDefaults.standard.setValue(true, forKey:
                "isConfigured")
           UserDefaults.standard.synchronize()
           workoutDuration = 0.0
               workoutTimer = Timer.scheduledTimer(timeInterval:
                    timerInterval, target: self, selector:
                    #selector(updateWorkoutData), userInfo: nil,
                    repeats: true)
           locationManager.startUpdatingLocation()
           lastSavedTime = Date()
           workoutStartTime = Date()
           
           WorkoutDataManager.sharedManager.createNewWorkout()
           
           if (CMMotionManager().isDeviceMotionAvailable &&
                        CMPedometer.isStepCountingAvailable() &&
                        CMAltimeter.isRelativeAltitudeAvailable()) {
                       //Start motion updates
                      isMotionAvailable = true
                     startPedometerUpdates()
               startActivityUpdates()
               startAltimeterUpdates()
                   } else {
                       NSLog("Motion acitivity not available on device.")
                       isMotionAvailable = false
                   }
           
           
   }
    func startAltimeterUpdates() {
            altimeter = CMAltimeter()
            altimeter?.startRelativeAltitudeUpdates(to:
                 OperationQueue.main, withHandler: { [weak self]
                 (altitudeData: CMAltitudeData?, error: Error?) in
                if let error = error {
                    NSLog("Error reading altimeter data:\(error.localizedDescription)")
    return }
                guard let altitudeData = altitudeData,
                    let relativeAltitude =
                      altitudeData.relativeAltitude as? Double
                       else { return }
                self?.workoutAltitude += relativeAltitude
            })
    }

    
    func startActivityUpdates() {
           motionManager = CMMotionActivityManager()
        motionManager?.startActivityUpdates(to:
                    OperationQueue.main, withHandler: { [weak self]
                       (activity: CMMotionActivity?) in
                   guard let activity = activity else { return }
                   if activity.walking {
                       self?.currentWorkoutType = WorkoutType.walking
                   } else if activity.running {
                       self?.currentWorkoutType = WorkoutType.running
                   } else if activity.cycling {
                       self?.currentWorkoutType =
                          WorkoutType.bicycling
                   } else if activity.stationary {
                       self?.currentWorkoutType =
                          WorkoutType.stationary
                   } else {
                                   self?.currentWorkoutType = WorkoutType.unknown
                   } })
    }
    func startPedometerUpdates() {
        guard let lastSavedTime = lastSavedTime
               else  { return }
        
        
        
      //  guard let workoutStartTime = workoutStartTime else {
 //   return }
            pedometer = CMPedometer()
        pedometer?.startUpdates(from: lastSavedTime, withHandler: {
              [weak self] (pedometerData: CMPedometerData?,  error: Error?) in
                if let error = error {
                              NSLog("Error reading pedometer data: \(error.localizedDescription)")
                              return
                }
                guard let pedometerData = pedometerData,
                           let distance = pedometerData.distance as? Double,
                           let averagePace = pedometerData.averageActivePace as? Double,
                           let steps = pedometerData.numberOfSteps as? Int,
                           let floorsAscended = pedometerData.floorsAscended  as? Int else { return }
            self?.workoutDistance += distance
                    self?.floorsAscended += floorsAscended
                    self?.workoutSteps += steps
                self?.averagePace = averagePace
            })
        
    }
    
    @objc func updateWorkoutData() {
        let now = Date()
        var workoutPaceText = String(format: "%.2f m/s | %0.2fm ", arguments: [averagePace, workoutAltitude])
        if let lastTime = lastSavedTime {
            self.workoutDuration +=
                    now.timeIntervalSince(lastTime)
         }
        self.workoutDuration += timerInterval
        workoutTimeLabel?.text = stringFromTime(timeInterval:
             self.workoutDuration)
        
       // workoutDistanceLabel?.text = String(format: "%.2f meters", arguments: [workoutDistance])
        
        
        
        workoutDistanceLabel?.text = String(format: "%.2fm | %d steps | %d floors", arguments: [workoutDistance, workoutSteps,
               floorsAscended])
             workoutPaceLabel?.text = String(format: "%.2f m /s", arguments: [averagePace])
          lastSavedTime = now
      }
    func stringFromTime(timeInterval: TimeInterval) -> String{
        let integerDuration = Int(timeInterval)
        let seconds = integerDuration % 60
        let minutes = (integerDuration / 60) % 60
        let hours = (integerDuration / 3600)
        if hours > 0 {
            return String("\(hours) hrs \(minutes) mins\(seconds) secs")
        } else {
            return String("\(minutes) min \(seconds) secs")
    } }
    
    
       func presentPermissionErrorAlert() {
           let alert = UIAlertController(title: "Permission Error", message: "Please enable location services for this app", preferredStyle:
                                            UIAlertController.Style.alert)
           let okAction = UIAlertAction(title: "OK", style:
                                            UIAlertAction.Style.default, handler: {
               (action:  UIAlertAction) in
               if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl,
                               options: [:], completionHandler: nil)
      } })
           let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
           alert.addAction(okAction)
           alert.addAction(cancelAction)
           self.present(alert, animated: true, completion: nil)
       }

}



extension CreateWorkoutViewController:
  CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager,
             didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
                case .authorizedWhenInUse:
                    requestAlwaysPermission()
                case .authorizedAlways:
                    startWorkout()
                    resetWorkoutData()
                case .denied:
                    presentPermissionErrorAlert()
        default:
            NSLog("Unhandled Location Manager Status: \(status)")
        }
        NSLog("Received permission change update!")
    }
    func locationManager(_ manager: CLLocationManager,
         didUpdateLocations locations: [CLLocation]) {
           guard let mostRecentLocation = locations.last else {
               NSLog("Unable to read most recent location")
               return
   }
        //Disable the old location calculation code
        //if let savedLocation = lastSavedLocation {
        //            let distanceDelta = savedLocation.distance(from: mostRecentLocation)
        //            workoutDistance += distanceDelta
         //       }
                lastSavedLocation = mostRecentLocation
        
    NSLog("Most recent location: \(String(describing: mostRecentLocation))")
        
        WorkoutDataManager.sharedManager.addLocation(coordinate:
              mostRecentLocation.coordinate)
        
    }
        
}
