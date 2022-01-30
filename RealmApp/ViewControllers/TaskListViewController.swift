//
//  TaskListViewController.swift
//  RealmApp
//
//  Created by  BoDim on 29.01.2022.
//

import RealmSwift
import UIKit

class TaskListViewController: UITableViewController {

    private var taskLists: Results<TaskList>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createTempData()
        taskLists = StorageManager.shared.realm.objects(TaskList.self)
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        
        let taskList = taskLists[indexPath.row]
        let currentTasks = taskList.tasks.filter("isComplete = false")
        
        var content = cell.defaultContentConfiguration()
        content.text = taskList.name
        if currentTasks.isEmpty && !taskList.tasks.isEmpty {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
            content.secondaryText = "\(currentTasks.count)"
        }
        cell.contentConfiguration = content

        return cell
    }
    
    //MARK: - UITableView Delegate
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        editAction.backgroundColor = .darkGray
        
        let doneAction = UIContextualAction(style: .normal, title: "Done") { _, _, isDone in
            StorageManager.shared.done(taskList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        doneAction.backgroundColor = .systemGreen
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }
    
    @IBAction func  addButtonPressed(_ sender: Any) {
        showAlert()
    }
    
    @IBAction func sortValueChanged(_ sender: UISegmentedControl) {
        taskLists = sender.selectedSegmentIndex == 0 ? taskLists.sorted(byKeyPath: "date") : taskLists.sorted(byKeyPath: "name")
        tableView.reloadData()
    }
    
 
    private func createTempData() {
        DataManager.shared.createTempData {
            self.tableView.reloadData()
        }
    }
}

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = AlertController.createAlert(withTitle: title, andMessage: "What do you want to do?")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(_ taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.save(taskList)
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
    
}
