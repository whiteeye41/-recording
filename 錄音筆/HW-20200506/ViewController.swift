//
//  ViewController.swift
//  HW-20200506
//
//  Created by cosima on 2020/5/6.
//  Copyright © 2020 cosima. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation
import CoreData


enum audiosession {
    case play
    case record
}
class ViewController: UIViewController,AVAudioRecorderDelegate,UITableViewDataSource,UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coreDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = myTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = coreDataArray[indexPath.row].fileName
        cell.detailTextLabel?.text = coreDataArray[indexPath.row].date
        return cell
    }
   
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag == true{
            do{
                audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
            }catch{
                print(error.localizedDescription)
            }
        }
        saveCoreData()
    }
    
    var audioRecorder:AVAudioRecorder?
    var audioPlayer:AVAudioPlayer?
    var isRecording: Bool = false
    var isPlaying = false
    var coreDataArray:[CoreDataType]=[]
    var newData:CoreDataType!
    var oneCell:IndexPath!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadFromCoreData()
    }
    
    
    @IBOutlet weak var myTableView: UITableView!
    
    @IBOutlet weak var recordingButton: UIBarButtonItem!
    
    
//    func time(){
//        let formattr = DateFormatter()
//        formattr.dateFormat = "yyyy/M/d HH:mm:ss"
//        formattr.timeZone = NSTimeZone.local
//
//        let string = formattr.string(from: Date())
//        print("現在時間:\(string)")
////        let date = formattr.date(from: "2019/1/1")
////        print(date!)
//    }
//
    
    func makeRecord() {

        let moc = CoreDataHelper.shared.managedObjectContext()
        newData = CoreDataType(context: moc)
        newData.fileName = "第\(coreDataArray.count+1)個語音備忘錄"
        coreDataArray.insert(newData, at: 0)
        
        let formattr = DateFormatter()
        formattr.dateFormat = "yyyy/M/d HH:mm:ss"
        formattr.timeZone = NSTimeZone.local
        let string = formattr.string(from: Date())
        newData.date = "\(string)"
        print("\(string)")
        
        let path = NSHomeDirectory() + "/Documents/" + "\(newData.fileID).caf"
        let url = URL(fileURLWithPath: path)
        
        let recodSetting:[String:Any]=[
            AVLinearPCMIsFloatKey:false,
            AVLinearPCMIsBigEndianKey:false,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 22050.0
        ]
        do{
            audioRecorder = try AVAudioRecorder(url: url, settings: recodSetting)
            audioRecorder?.delegate = self
            
        }
        catch {
            print("error\(error.localizedDescription)")
        }
    }
    
    @IBAction func recorder(_ sender: UIBarButtonItem) {
        if isRecording == false {
            makeRecord()
            settingAudio(tomode: .record)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
            recordingButton.title = "錄音中"
            myTableView.reloadData()
        }else if isRecording == true{
            settingAudio(tomode: .play)
            audioRecorder?.stop()
            isRecording = false
            recordingButton.title = "錄音"
            myTableView.reloadData()
        }
        saveCoreData()
    }
    
    //設置音訊
    func settingAudio(tomode mode:audiosession){
        let session  = AVAudioSession.sharedInstance()
        do{
            switch mode {
            case .record:
                try? session.setCategory(AVAudioSession.Category.playAndRecord)
                
            case .play:
                try? session.setCategory(AVAudioSession.Category.playback)
            }
            try session.setActive(false)
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    //播放音樂
    @IBAction func play(_ sender: UIBarButtonItem) {
        guard oneCell != nil else{
            let caveat = UIAlertController(title: "錯誤訊息", message: "忘了點選檔案", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
           caveat.addAction(okAction)
           present(caveat, animated: true, completion: nil)
            return
        }
        playAudio(selectCell:oneCell)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if oneCell ==  indexPath {
            tableView.deselectRow(at: indexPath, animated: true)
            oneCell = nil
        }else{
        oneCell = indexPath
        }
        
    }
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        print("aaa")
//    }
    func playAudio (selectCell:IndexPath){
        let selectFileName = coreDataArray[selectCell.row].fileID
        let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(selectFileName).caf")
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        }catch{
            print(error.localizedDescription)
        }
        if isRecording == false{
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        }
        isPlaying = true
    }
    
    
    func loadFromCoreData(){
        let moc = CoreDataHelper.shared.managedObjectContext()
        let fetchRequest = NSFetchRequest<CoreDataType>(entityName: "Audio")
        
        moc.performAndWait {
            do{
                self.coreDataArray = try moc.fetch(fetchRequest)
                print("執行coreData檔案匯入self.coreDataArray = try moc.fetch(request)")
                
            }catch{
                print("error=\(error)")
                coreDataArray=[]
            }
        }
    }
    
    func saveCoreData(){
        CoreDataHelper.shared.saveContext()
    }
    
    //刪除方法二
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            
            let controller = UIAlertController(title: nil, message: "確定要刪除?", preferredStyle: .actionSheet)
            
            let deleteAction = UIAlertAction(title: "刪除", style: .destructive) { (action:UIAlertAction) in
                
                self.dismiss(animated: true, completion: nil)
                let deleData = self.coreDataArray.remove(at: indexPath.row)
                let coreData = CoreDataHelper.shared.managedObjectContext()
                coreData.delete(deleData)
                self.myTableView.deleteRows(at: [indexPath], with: .automatic)
                
                
                let deletefile = "\(deleData.fileID).caf"
                let document = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
                let deleteURL = document.appendingPathComponent(deletefile)
                do{
                    try FileManager.default.removeItem(at: deleteURL)
                }catch{
                    print("無法刪除檔案夾")
                }
                
                self.saveCoreData( )
            }
            controller.addAction(deleteAction)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action:UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }
            controller.addAction(cancelAction)
            
            self.present(controller, animated: true, completion: nil)
            completionHandler(true)
        }
        
        let shareAction = UIContextualAction(style: .normal, title: "分享") { (action, view, completionHandler) in
            
            let uploadFileID = self.coreDataArray[indexPath.row].fileID
            let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(uploadFileID).caf")
            
            let activityController = UIActivityViewController(activityItems: [url], applicationActivities:nil)
    
            self.present(activityController,animated: true)

            completionHandler(true)
        }
        
        deleteAction.backgroundColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
        deleteAction.image = UIImage(systemName: "trash")
        
        shareAction.backgroundColor = UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1)
        shareAction.image = UIImage(systemName: "square.and.arrow.up.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
    
//    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        
//        let shareAction = UIContextualAction(style: .normal, title: "分享") { (action, view, completionHandler) in
//            
//            let uploadFileID = self.coreDataArray[indexPath.row].fileID
//            let url = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/\(uploadFileID).caf")
//            
//            let activityController = UIActivityViewController(activityItems: [url], applicationActivities:nil)
//            
//            self.present(activityController,animated: true)
//            
//            completionHandler(true)
//        }
//        shareAction.backgroundColor = UIColor(red: 139/255, green: 137/255, blue: 137/255, alpha: 1)
//        shareAction.image = UIImage(systemName: "play.fill")
//        return UISwipeActionsConfiguration(actions: [shareAction])
//    }
    //刪除方法1
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//
//        if editingStyle == .delete {
//
//            let controller = UIAlertController(title: nil, message: "確定要刪除?", preferredStyle: .actionSheet)
//
//            let deleteAction = UIAlertAction(title: "刪除", style: .destructive) { (action:UIAlertAction) in
//                self.dismiss(animated: true, completion: nil)
//                let deleData = self.coreDataArray.remove(at: indexPath.row)
//                let coreData = CoreDataHelper.shared.managedObjectContext()
//
//                coreData.performAndWait {
//                    coreData.delete(deleData)
//                    self.myTableView.deleteRows(at: [indexPath], with: .automatic)
//                    self.saveCoreData( )
//                }
//            }
//            controller.addAction(deleteAction)
//            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (action:UIAlertAction) in
//                self.dismiss(animated: true, completion: nil)
//            }
//            controller.addAction(cancelAction)
//            present(controller, animated: true, completion: nil)
//        }
//    }
//
    override func viewDidLoad() {
        
        super.viewDidLoad()
        myTableView.dataSource = self
        myTableView.delegate = self
        
    }
}
