//
//  WorkoutTableViewController.swift
//  FItios
//
//  Created by Ersan on 16/01/2022.
//

import UIKit

class WorkoutTableViewController: UITableViewController {

    var workouts: [Workout]?
    let dateFormatter = DateFormatter()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.workouts?.count ?? 0
    }

    override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         WorkoutDataManager.sharedManager.loadWorkoutsFromHealthKit
          { [weak self] (fetchedWorkouts: [Workout]?) in
             if let fetchedWorkouts = fetchedWorkouts {
                 self?.workouts = fetchedWorkouts
                 DispatchQueue.main.async {
                                  self?.tableView?.reloadData()
                 } }
                 } }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:
                "workoutCell", for: indexPath)
             guard let workouts = workouts else {
                 return cell
        }
              let selectedWorkout = workouts[indexPath.row]
              let dateString = dateFormatter.string(from:selectedWorkout.startTime)
        let durationString = "" //WorkoutDataManager.sharedManager.stringFromTime(timeInterval:selectedWorkout.duration)
              let titleText = " \(dateString) |\(selectedWorkout.workoutType) | \(durationString)"
              let detailText = String(format: "%.0f m | %.0f floors",
                 arguments: [selectedWorkout.distance,
                 selectedWorkout.flightsClimbed])
              cell.textLabel?.text = titleText
              cell.detailTextLabel?.text = detailText
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
