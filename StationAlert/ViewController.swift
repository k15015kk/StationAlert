//
//  ViewController.swift
//  StationAlert
//
//  Created by k15015kk on 2017/08/01.
//  Copyright © 2017年 HarukiInoue. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import CoreLocation
import MapKit
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate{

    
    let STATION_INFO = "StationInfo"
    let RAIL_INFO = "RailInfo"
    private var stationDatas: [StationInfo] = []
    private var railDatas: [RailInfo] = []
    
    var falseCount = 0;
    
    var locationManager: CLLocationManager!
    
    var nowPointLat:Double = 0.0
    var nowPointLng:Double = 0.0
    
    let context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var mapKitView: MKMapView!
    @IBOutlet weak var beginLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var lineAndStationNameLabel: UILabel!
    
    var nowTrainLine: String = ""
    var nowStationName: String = ""
    var nowSpeed: Int = 0
    
    var nearStationFlag: Bool = false
    var stopStationFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.activityType = .otherNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        // locationManager.distanceFilter = 100.0
        
        // MapViewの設定
        mapKitView.setCenter(mapKitView.userLocation.coordinate, animated: true)
        mapKitView.userTrackingMode = MKUserTrackingMode.follow
        
        // LabelViewの設定
        beginLabel.text = "ただいま"
        endLabel.text = "に居ます"
        
        lineAndStationNameLabel.backgroundColor = UIColor(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1.0)
        lineAndStationNameLabel.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lineAndStationNameLabel.text = "線路上外"
        
        // セキュリティ認証のステータスを取得.
        let status = CLLocationManager.authorizationStatus()
        print("authorizationStatus:\(status.rawValue)")
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        // (このAppの使用中のみ許可の設定) 説明を共通の項目を参照
        if(status == .notDetermined) {
            self.locationManager.requestWhenInUseAuthorization()
        }

        
        // 初期データを格納
        print("-parseStationStart-")
        parseStationGeoJson(context: context)
        print("-parseRailStart-")
        parseRailDataGeoJson(context: context)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // データベース内のデータを読み込む
    func loadStationDatas(context: NSManagedObjectContext) -> [StationInfo] {
        
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: STATION_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lineName", ascending: true)]
        
        // Core Dataを経由してデータベースにアクセス
        do {
            if let stationDatas = try context.fetch(fetchRequest) as? [StationInfo] {
                print(stationDatas.count)    // データベースのデータ数出力
                return stationDatas
            }
            else  {
                return []
            }
        }
        
        // エラー処理
        catch let error as NSError{
            print(error.localizedDescription)
            return []
        }
    }
    
    // データベース内のデータを読み込む
    func loadStationDatas(context: NSManagedObjectContext,line: String) -> [StationInfo] {
        
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: STATION_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = NSPredicate(format: "lineName == %@", line)
        
        // Core Dataを経由してデータベースにアクセス
        do {
            if let stationDatas = try context.fetch(fetchRequest) as? [StationInfo] {
                print(stationDatas.count)    // データベースのデータ数出力
                return stationDatas
            }
            else  {
                return []
            }
        }
            
            // エラー処理
        catch let error as NSError{
            print(error.localizedDescription)
            return []
        }
    }

    // データベース内のデータを読み込む
    func loadRailDatas(context: NSManagedObjectContext) -> [RailInfo] {
        
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: RAIL_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        
        // Core Dataを経由してデータベースにアクセス
        do {
            if let railDatas = try context.fetch(fetchRequest) as? [RailInfo] {
                print(railDatas.count)    // データベースのデータ数出力
                return railDatas
            }
            else  {
                return []
            }
        }
            
            // エラー処理
        catch let error as NSError{
            print(error.localizedDescription)
            return []
        }
    }
    
    // データベース内のデータを読み込む
    func loadRailDatas(context: NSManagedObjectContext,lat: Double,lng: Double) -> [RailInfo] {
        
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: RAIL_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        
        fetchRequest.predicate = NSPredicate(format: "latitude BETWEEN{%f,%f} AND longitude BETWEEN{%f,%f}",lat - 0.01, lat + 0.01, lng - 0.01, lng + 0.01)
        
        // Core Dataを経由してデータベースにアクセス
        do {
            if let railDatas = try context.fetch(fetchRequest) as? [RailInfo] {
                print(railDatas.count)    // データベースのデータ数出力
                return railDatas
            }
            else  {
                return []
            }
        }
            
            // エラー処理
        catch let error as NSError{
            print(error.localizedDescription)
            return []
        }
    }

    // MARK: 駅データをパース
    
    private func parseStationGeoJson(context: NSManagedObjectContext) {
        
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: STATION_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        
        // エンティティを定義
        let entity: NSEntityDescription! = NSEntityDescription.entity(forEntityName: STATION_INFO, in: context)
        
        do {
            let results: Array = try context.fetch(fetchRequest)
            
            print(results.count)    // データベースのデータ数出力
            
            // ファイルパス
            let jsonDataPath: NSString = Bundle.main.path(forResource: "N02-16_Station_Meitetsu", ofType: "json")! as NSString
            let jsonRawData: NSData! = NSData(contentsOfFile: jsonDataPath as String)
            
            // JSONパース
            let jsonDictionary: [[String: AnyObject]]
            do {
                jsonDictionary = try JSONSerialization.jsonObject(with: jsonRawData as Data, options: []) as! [[String: AnyObject]]
            }
            // エラー処理
            catch {
                print("Error JSONObjectWithData:\(error)")
                return
            }
            
            // 配列にキャストしたJSONデータを格納
            let top = jsonDictionary as NSArray
            
            var stationDataSum = 0
            
            for roop in top {
                // パースしたデータを分割
                let next = roop as! NSDictionary
                let geometory = next["geometry"] as! NSDictionary
                let coord = geometory["coordinates"] as! NSArray
                
                // 緯度経度データをカウント
                for coordData in coord {
                    let data = coordData as! NSArray
                    stationDataSum += data.count / 2
                }
                
            }
            
            print(stationDataSum)
            
            if (results.count == 0 || results.count > stationDataSum || results.count < stationDataSum) {
                
                // データベースを全削除
                let deleteAll = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteAll)
                }
                catch {
                    print("Error excuteRequest(deleteAll):\(error)")
                }
                
                // データがある間ループ
                for roop in top {
                    
                    // パースしたデータを分割
                    let next = roop as! NSDictionary
                    let geometory = next["geometry"] as! NSDictionary
                    let properties = next["properties"] as! NSDictionary
                    let coord = geometory["coordinates"] as! NSArray
                    
                    for coordData in coord {
                        // データベースにアクセス
                        let stationInfo:StationInfo = StationInfo(entity: entity, insertInto: context)
                        
                        // データベースに値格納
                        stationInfo.setValue(properties["駅名"] as! String, forKey: "stationName")
                        stationInfo.setValue(properties["路線名"] as! String, forKey: "lineName")
                        stationInfo.setValue(properties["運営会社"] as! String, forKey: "company")
                        
                        let data = coordData as! NSArray
                        stationInfo.setValue(data[0] as! Double, forKey: "longitude")
                        stationInfo.setValue(data[1] as! Double, forKey: "latitude")
                        
                        do {
                            try context.save()
                        }
                        catch {
                            print("Error save:\(error)")
                        }
                    }
                
                }
            }
            
        } catch let error as NSError {
            // エラー処理
            print("FETCH ERROR:\(error.localizedDescription)")
        }

    }
    
    // MARK: 路線データをパース
    
    private func parseRailDataGeoJson(context: NSManagedObjectContext) {
        // フェッチリクエスト
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: RAIL_INFO)
        fetchRequest.returnsObjectsAsFaults = false
        
        // エンティティを定義
        let entity: NSEntityDescription! = NSEntityDescription.entity(forEntityName: RAIL_INFO, in: context)
        
        do {
            let results: Array = try context.fetch(fetchRequest)
            
            print(results.count)    // データベースのデータ数出力
            
            // ファイルパス
            let jsonDataPath: NSString = Bundle.main.path(forResource: "N02-16_RailroadSection_Meitetsu", ofType: "json")! as NSString
            let jsonRawData: NSData! = NSData(contentsOfFile: jsonDataPath as String)
            
            // JSONパース
            let jsonDictionary: [[String: AnyObject]]
            do {
                jsonDictionary = try JSONSerialization.jsonObject(with: jsonRawData as Data, options: []) as! [[String: AnyObject]]
            }
            // エラー処理
            catch {
                print("Error JSONObjectWithData:\(error)")
                return
            }
            
            // 配列にキャストしたJSONデータを格納
            let top = jsonDictionary as NSArray
            
            var railDataSum = 0
            
            for roop in top {
                // パースしたデータを分割
                let next = roop as! NSDictionary
                let geometory = next["geometry"] as! NSDictionary
                let coord = geometory["coordinates"] as! NSArray
                
                // 緯度経度データをカウント
                for coordData in coord {
                    let data = coordData as! NSArray
                    railDataSum += data.count / 2
                }
                
            }
            
            // 緯度経度データを出力
            print("railData = \(railDataSum)")
            
            if (results.count == 0 || results.count > railDataSum || results.count < railDataSum) {
                
                // データベースを全削除
                let deleteAll = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteAll)
                }
                catch {
                    print("Error excuteRequest(deleteAll):\(error)")
                }
                
                
                // データがある間ループ
                for roop in top {
                    
                    // パースしたデータを分割
                    let next = roop as! NSDictionary
                    let geometory = next["geometry"] as! NSDictionary
                    let properties = next["properties"] as! NSDictionary
                    let coord = geometory["coordinates"] as! NSArray
                    
                    for coordData in coord {
                        // データベースにアクセス
                        let railInfo:RailInfo = RailInfo(entity: entity, insertInto: context)
                        
                        // データベースに値格納
                        railInfo.setValue(properties["路線名"] as! String, forKey: "lineName")
                        railInfo.setValue(properties["運営会社"] as! String, forKey: "company")
                        
                        let data = coordData as! NSArray
                        railInfo.setValue(data[0] as! Double, forKey: "longitude")
                        railInfo.setValue(data[1] as! Double, forKey: "latitude")
                        
                        do {
                            try context.save()
                        }
                        catch {
                            print("Error save:\(error)")
                        }
                    }
                    
                }
            }
            
        } catch let error as NSError {
            // エラー処理
            print("FETCH ERROR:\(error.localizedDescription)")
        }

    }
    
    func onStationFLag(lat: Double,lng: Double) -> Bool{
        var minStationDistance: Double = 99999
        var minStationName: String = ""
        stationDatas = loadStationDatas(context: context, line: nowTrainLine)
        
        for datas in stationDatas {
            let nowPoint: CLLocation = CLLocation(latitude: nowPointLat, longitude: nowPointLng)
            let dataPoint: CLLocation = CLLocation(latitude: datas.latitude, longitude: datas.longitude)
            
            let distance = dataPoint.distance(from: nowPoint)
            
            if distance < minStationDistance {
                minStationDistance = distance
                minStationName = datas.stationName!
            }
        }
        
        if minStationDistance <= 100 {
            nowStationName = minStationName
            return true
        } else {
            return false
        }
    }
    
    func onRailFlag (lat: Double,lng: Double) -> Bool {
        // 半径およそ１ｋｍ内のデータを格納
        railDatas = loadRailDatas(context: context, lat: nowPointLat, lng: nowPointLng)
        
        
        // 線路上にいるかどうかを判別
        var minDistance: Double = 99999
        var minLineName: String = ""
        
        if railDatas.count == 0 {
            return false
        } else {
            
            for datas in railDatas {
                let nowPoint: CLLocation = CLLocation(latitude: nowPointLat, longitude: nowPointLng)
                let dataPoint: CLLocation = CLLocation(latitude: datas.latitude, longitude: datas.longitude)
                
                let distance = dataPoint.distance(from: nowPoint)
                
                if distance < minDistance {
                    minDistance = distance
                    minLineName = datas.lineName!
                }
            }
            
            if minDistance <= 100 {
                nowTrainLine = minLineName
                return true
            } else {
                return false
            }
        }
    }
    
    // 位置情報取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // 現在地の情報を格納
        nowPointLat = Double((locations.last?.coordinate.latitude)!)
        nowPointLng = Double((locations.last?.coordinate.longitude)!)
        
        nowSpeed = Int(round((locations.last?.speed)! * 3.6))
        
        // 現在地の出力
        print(nowPointLat)
        print(nowPointLng)

        let railFlag: Bool = onRailFlag(lat: nowPointLat, lng: nowPointLng)
        let stationFlag: Bool = onStationFLag(lat: nowPointLat, lng: nowPointLng)
        
        // 画面Labelの切り替え
        if stationFlag {
            
            if nearStationFlag == false {
                let content = UNMutableNotificationContent()
                content.title = "駅通知"
                content.body = "まもなく\(nowStationName)駅です"
                content.sound = UNNotificationSound.default()
                
                content.categoryIdentifier = "message"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "OneSecond", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
                
                nearStationFlag = true
            }
            
            lineAndStationNameLabel.text = nowStationName
            lineAndStationNameLabel.backgroundColor = UIColor(red: 0.82745098039, green: 0.18431372549, blue: 0.18431372549, alpha: 1.0)
            
            if nowSpeed <= 5 {
                
                if stopStationFlag == false {
                    let content = UNMutableNotificationContent()
                    content.title = "駅通知"
                    content.body = "ただいま\(nowStationName)駅に停車中"
                    content.sound = UNNotificationSound.default()
                    
                    content.categoryIdentifier = "message"
                    
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "OneSecond", content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
                    stopStationFlag = true
                }
                
                endLabel.text = "停車中"
            } else {
                endLabel.text = "付近"
            }
            
            falseCount = 0
            
        } else if railFlag {
            
            stopStationFlag = false
            nearStationFlag = false
            
            lineAndStationNameLabel.text = nowTrainLine
            lineAndStationNameLabel.backgroundColor = UIColor(red: 0.21960784313, green: 0.55686274509, blue: 0.23529411764, alpha: 1.0)
            endLabel.text = "走行中"
            
            falseCount = 0
        } else {
            
            stopStationFlag = false
            nearStationFlag = false
            
            falseCount += 1
            
            if  falseCount > 10 {
                lineAndStationNameLabel.backgroundColor = UIColor(red: 0.1294117647, green: 0.1294117647, blue: 0.1294117647, alpha: 1.0)
                lineAndStationNameLabel.textColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                lineAndStationNameLabel.text = "線路上外"
                endLabel.text = "に居ます"
                
                falseCount = 0
            }
        }

    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            case .notDetermined:
                print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
                // 許可を求めるコードを記述する（後述）
                break
            case .denied:
                print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
                // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
                break
            case .restricted:
                print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
                // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
                break
            case .authorizedAlways:
                print("常時、位置情報の取得が許可されています。")
                locationManager.startUpdatingLocation()
                break
            case .authorizedWhenInUse:
                print("起動時のみ、位置情報の取得が許可されています。")
                locationManager.startUpdatingLocation()
                break
        }
    }

    // 位置情報エラー
    func locationManager(_ manager: CLLocationManager,didFailWithError error: Error){
        print("error")
    }
}

