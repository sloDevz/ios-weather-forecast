# 🌤️ 날씨 앱

# 🍀 Team MeLo 🌏

🏃🏻🏃🏻‍♂️💨 **프로젝트 기간:** `23.03.13` ~ `23.04.14`

| <img src="https://avatars.githubusercontent.com/u/29590768?v=4" width=200> | <img src="https://avatars.githubusercontent.com/u/59835351?v=4" width=200> |
| --- | --- |
| [🍀 Logan 🍀](https://github.com/sloDevz) | [🌏 Mason 🌏](https://github.com/qwerty3345) |

> 리뷰어: 라자냐( @wonhee009 )

# 📱 구현화면

![Simulator Screen Recording - iPhone 14 Pro - 2023-04-13 at 13.34.09.gif](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/a313d072-97a9-4df5-bf68-ec35a20f9ad2/Simulator_Screen_Recording_-_iPhone_14_Pro_-_2023-04-13_at_13.34.09.gif)


# ✨ 핵심 키워드

- 네트워킹
    - 범용성과 재사용성, 유연성을 고려한 네트워킹 타입 구현
        - Repository, NetworkService의 레이어 분리
        - Endpoint 객체 분리를 통한 확장성 있는 프로그램 설계
    - URLSession
        - Completion handler 방식에서 
        Swift Concurrency 를 활용한 async await 방식으로 리팩터링
- 컬렉션뷰 구현
    - FlowLayout의 기본 구현 → CompositionalLayout list 구현으로 리팩터링
- CoreLocation
    - 사용자 위치 권한 체크 및 부여
    - 현재 좌표, 주소 가져오기
- 이미지 캐싱
    - NSCache 를 활용
- Core Graphics 를 활용한 그래프 구현
    - 라이브러리를 사용하지 않고, 날씨 데이터를 그래프로 직접 그리게 구현

# **⁉️ 고민과 해결**

## STEP1

### 1️⃣ API 키 숨기기

- `APIKey.xcconfig` 라는 파일을 생성하고, 해당 파일을 .gitignore에 추가한 뒤
Info.plist 에서 해당 키값을 받아와서 `Bundle.main.object(forInfoDIctionaryKey:)` 방식으로 해당 값을 받아옴
- git이 추적하는 프로젝트 폴더 바로 바깥 폴더에 해당 configuration 파일을 두고, relative path (../../../APIKey.xcconfig) 로 설정하여 처리

### 2️⃣ Repository의 역할, Service의 역할

## STEP2

### 1️⃣ LocationManager를 관리하는 객체 분리

- 사용자의 위치를 받아오는 기능에 대해서는 날씨 앱 특성상 사용자의 위치를 계속해서 업데이트 할 필요는 없다 생각하여 필요할 때만 위치를 받아오는 것으로 구현.
    - 공식문서 참고하여 스스로 `locationManager`의 `delegate`를 처리하는 `LocationDataManager`를 만들어서 구현.
        
        > https://developer.apple.com/documentation/corelocation/configuring_your_app_to_use_location_services
        > 
- 구현 초기엔 `fetchLocation` 후에 델리게이트 방식으로 넘어오는 데이터를 다시 VC로 넘기는 과정에서 `completionHandler` 로 `closure` 를 할당하여 처리하는 식으로 구현.
    
    ```swift
    // 구현 초기 -> CompletionHandler 로 처리
    final class LocationDataManager: NSObject, CLLocationManagerDelegate {
    		let locationManager = CLLocationManager()
        private var locationUpdateCompletion: ((CLLocation) -> Void)?
    
    		// completion을 할당하고 위치를 요청
    		func requestLocation(completion: @escaping (CLLocation?) -> Void) {
            locationUpdateCompletion = completion
            locationManager.requestLocation()
        }
    
    		// 완료된 후, completion에 넘기고 nil을 할당해서 해제
    		func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            locationUpdateCompletion?(location)
            locationUpdateCompletion = nil
        }
    
    // ViewController
    class ViewController: UIViewController {
    		// 호출 시...
    		locationDataManager.requestLocation { [weak self] location in
    				self?.location = location
        }
    ```
    
    > 이렇게 메모리 누수를 방지하기 위해 didUpdateLocations 로 결과값이 넘어온 뒤, completion에 nil을 할당.
    > 
- 하지만 사용자 위치 권한 설정도 동일한 로직으로 작성할 때 문제가 발생했는데,
사용자 권한에 대한 delegate 메서드는 프로그램이 시작되고 얼마 지나지 않아 알아서 불리는 메서드의 특징을 지니기 때문에 `completion` 이 바로 nil이 되는 현상이 발생.
    
    > flag 를 두거나, 시간을 체크하는 등 여러 우회방법이 있긴 하겠지만 본질적인 해결이 아니라 생각.
    > 
- 고민끝에 해당 LocationDataManager의 delegate를 설정하자는 판단을 하게 됨.
- `CLLocationManager` 객체의 delegate를 처리하는 LocationDataManager의 delegate를 설정하는 것이 비효율적인게 아닌가 라는 생각이 들었지만,
내부 처리를 추상화하여 원하는 데이터만 뷰컨트롤러로 넘길 수 있다는 데서 장점이 있다고 판단했기에 진행.

### 2️⃣ OSLog 활용

- 특별한 `error handling` 하지 않는 상황에서 print 문으로 처리해놓았던 구문들을 OSLog 를 활용하여 기록이 남을 수 있게 변경
- OSLog 의 메시지로는 `StaticString` 만을 허용하기 때문에 swift의 string interpolation 으로는 메시지를 작성할 수 없다고 하여, Objective-C의 string interpolation 방식인 `“%@”`을 사용하여 출력하도록 구현
    
    ```swift
    func log(_ log: OSLog, error: Error) {
        os_log(.error, log: log, "%@", error.localizedDescription)
    }
    ```
    

## STEP3

### 💰 이미지 캐싱 구현

- 날씨 아이콘 이미지를 처음에는 assets 에 저장해뒀다가, 서버에서는 받아온 id 값과 매칭시켜서 업데이트를 해주려 했지만, 프로젝트 요구사항에 따라 이미지를 다운받는 식으로 변경
- 매번 모든 이미지를 다운받는 것의 단점을 느껴,
NSCache를 활용한 이미지 캐시 매니저를 구현하고 이미지가 캐시에 존재한다면 캐싱을 통해 받아오도록 처리.
- 이 때 이미지가 캐시에 존재하는지 아닌지에 대한 체크는 Repository에서 요청을 할 때 하도록 구현.

### 🗓️ DateFormatter 구현

- 서버에서 받아온 “2023-04-06 14:22:00” 형태의 날짜 데이터를
요구사항인 “04/06(목) 14시” 형태로 변경하기 위해 DateFormatter 로직을 구현.
- 처음엔 아래처럼 DateFormatter 의 extension을 구현해서 처리해줬지만, 이 로직에서 몇가지 단점을 발견.
1. extension이라는 점
- 특정 경우 (셀에 표시)에만 쓰이는 로직이기에,
모든 dateFormatter가 해당 메서드를 알 필요는 없을 듯 해보였음
2. 모든 cell이 매번 dateFormatter 인스턴스를 생성한다는 점
- dateFormatter를 VC의 프로퍼티로 빼는 것으로 해결은 가능
3. 매번 DateFormatter의 dateFormat을 2번씩 변경 해주는 로직이 존재함
- 그렇게 큰 비용이 아닐 수 있지만, CollectionView Cell 에 사용되는 로직이기에 아주 빠른 시간 내에 여러번 호출되는 성격을 지닌다고 판단함
    
    ```swift
    extension DateFormatter {
        func dateString(with dateString: String) -> String {
            self.dateFormat = "yyyy-MM-dd HH:mm:ss"
            guard let date = self.date(from: dateString) else { return "Formatting dateString fail"}
    
            self.dateFormat = "MM/dd(EEE) HH시"
            let formattedDate = self.string(from: date)
    
            return formattedDate
        }
    }
    ```
    
    ```swift
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    		...
        let date = DateFormatter().dateString(with: weather.dateString)
        cell.configure(date: date, temperature: temperature, iconCode: iconCode)
    		...
    }
    ```
    
- 위와 같은 문제를 해결하기 위해 이처럼 static 한 DateFormatter 인스턴스를 생성 해 놓고, 해당 인스턴스를 사용하는 static func 를 구현하는 방식으로 Util을 만듦.
    
    > 서버에서 내려오는 데이터 중 Int 값인 `timestamp` 가 존재하기에, 바로 Date 로 변환이 가능했다.
    > 
    - 앱이 종료되기 전까지 계속해서 Cell을 표시하기 위해 사용되는 성격이기에 static이 적절하다고 생각했음.
    
    ```swift
    enum DateFormatUtil {
        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd(EEE) HH시"
            return formatter
        }()
        
        static func format(with timestamp: Int) -> String {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    
            let formattedDate = dateFormatter.string(from: date)
            return formattedDate
        }
    }
    ```
    
- 이 때 static 한 dateFormatter 인스턴스 계속해서 사용하는 방식이므로 Thread Safety가 걱정되긴 했지만, 공식문서의 DateFormatter는 Thread Safe 하다는 문구를 보고 해당 방식을 사용해도 문제없는 더 효율적인 로직이라 판단
    
    > 공식문서: On iOS 7 and later NSDateFormatter is thread safe.
    > 

### 🎨 HeaderView만 따로 업데이트하게끔 구현

- 컬렉션뷰의 헤더뷰에서 필요로 하는 API 데이터는 현재 날씨 데이터이고,
셀에서 필요로 하는 데이터는 주간 날씨 데이터여서 각각의 API 요청이 별도로 이루어짐
- 처음에는 헤더뷰를 업데이트 하기 위해서 CollectionView의 reloadData 해주었지만, 헤더뷰를 업데이트 하기 위해 전체 셀들을 업데이트 하는 것은 비효율적이란 생각이 들어 헤더뷰만 업데이트 하도록 리팩터링
    
    ```swift
    guard let headerView = self.collectionView.visibleSupplementaryViews(
        ofKind: UICollectionView.elementKindSectionHeader
    ).first as? WeatherHeaderView else { return }
    
    headerView.configure(
        with: currentWeather.weatherDetail,
        address: "\\(placemark.locality ?? "") \\(placemark.name ?? "")",
        icon: image
    )
    ```
    

### 🌐 두 개의 네트워킹 통신이 완료되는 시점 파악

- “현재 날씨” 와 “날씨 예보” 가 모두 완료된 후 `Refresh Control` 을 `endRefreshing` 처리해주기 위해, 
DispatchGroup 을 사용하여 구현
- 각각의 날씨 요청이 시작될 때 `enter()`, 끝났을 때 `leave()`를 호출하고 완료된 시점에 `notify()`에서 endRefreshing 이 호출되도록 처리

### 🌐 API Endpoint, Generic 를 통한 확장성 있는 네트워킹 구현

- 프로젝트 스텝이 진행되며 icon 이미지 API 요청이 추가되는 등, 요구사항이 변경되며 매번
- enum과 연관값을 활용하여,
    - 호출하는 repository에서

```swift
enum OpenWeatherAPIEndpoints {
    case weather(coordinate: Coordinate)
    case forecast(coordinate: Coordinate)
    case iconImage(id: String)
}

extension OpenWeatherAPIEndpoints {
    var endpoint: Endpoint {
        switch self {
        case .weather(let coordinate):
            return Endpoint(baseURL: "https://api.openweathermap.org",
                            path: "/data/2.5/weather",
                            queryItems: generateQueryItems(coordinate: coordinate))
		...
		var urlRequest: URLRequest? { 
				// Endpoint 를 URLRequest 로 변환하는 로직
		}
		...
```

```swift
struct Endpoint {
    let baseURL: String
    let path: String
    let queryItems: [URLQueryItem]?
    let httpMethod: HTTPMethodType
}
```

- 또한 제네릭을 활용 해, fetchForecast, fetchWeather 의 메서드를 하나로 처리

```swift
func fetchData<T: Decodable>(type: T.Type,
                             endpoint: OpenWeatherAPIEndpoints) async throws -> T {
    guard let urlRequest = endpoint.urlRequest else { throw NetworkError.invalidURL }

    let data = try await service.performRequest(with: urlRequest)
    let decodedData = try self.deserializer.deserialize(T.self, data: data)
    return decodedData
}
```

## STEP4

### 🚤 Swift Concurrency 적용 (리팩토링)

- 기존의 Completion Handler 방식의 URLSessionDataTask 네트워킹 요청은 완료 시점을 코드로 직관적으로 파악하기 어렵고, 중첩된 클로저 구문이 발생한다는 단점이 존재
- 특히, 이번 프로젝트에서 
”날씨 API 요청 → 완료 시점 → 날씨 아이콘 API 요청 → 완료” 와 같이 두 개의 네트워킹 요청을 종속적으로 처리해야 하는 상황이 발생함.

> **리팩터링 전)**
> 

```swift
final class NetworkService {
		func performRequest(with url: URL?,
                        httpMethodType: HTTPMethodType,
                        completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url else {
            completion(.failure(.invalidURL))
            log(.network, error: NetworkError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethodType.rawValue
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                completion(.failure(.networking))
                log(.network, error: NetworkError.networking)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.response))
                log(.network, error: NetworkError.response)
                return
            }

            guard let data else {
                completion(.failure(.invalidData))
                log(.network, error: NetworkError.invalidData)
                return
            }

            completion(.success(data))
        }
        task.resume()
    }
}
```

```swift
// (Service ->) Repository를 통해 데이터를 받아오는 ViewController 내부
private func fetchWeather(coordinate: Coordinate) {
		// 1️⃣ API 에서 날씨 데이터를 먼저 받아옴
    repository.fetchWeather(coordinate: coordinate) { currentWeather in
					// 2️⃣ 받아온 해당 날씨 데이터를 바탕으로, API에서 날씨 아이콘 이미지 데이터를 받아옴
					// 😵 중첩 클로저 발생..!
			    repository.fetchWeatherIconImage(withID: currentWeather.weathers.first?.icon ?? "") { iconImage in
								// 받아온 iconImage로 View 업데이트
					}
		}	
}
```

- 이를 해결하기 위해 Swift Concurrency 의 async-await 방식으로 리팩터링 진행
    - 리팩터링 후 각 요청간의 순서와 코드의 흐름이 쉽게 파악됨

> **리팩터링 후)**
> 

```swift
final class OpenWeatherRepository {
...
		func fetchData<T: Decodable>(type: T.Type,
                                 endpoint: OpenWeatherAPIEndpoints) async throws -> T {
        guard let urlRequest = endpoint.urlRequest else { throw NetworkError.invalidURL }

        let data = try await service.performRequest(with: urlRequest)
        let decodedData = try self.deserializer.deserialize(T.self, data: data)
        return decodedData
    }
...
}

final class NetworkService {
    func performRequest(with urlRequest: URLRequest?) async throws -> Data {
        guard let urlRequest else {
            log(.network, error: NetworkError.invalidURL)
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            log(.network, error: NetworkError.response)
            throw NetworkError.response
        }
        return data
    }
}
```

```swift
// (Service ->) Repository를 통해 데이터를 받아오는 ViewController 내부
private func fetchWeather(coordinate: Coordinate) {
	  Task {
				// 1️⃣ API 에서 날씨 데이터를 먼저 받아옴
	      let currentWeather = try await repository.fetchData(type: CurrentWeather.self,
	                                                          endpoint: .weather(coordinate: coordinate))
				// 2️⃣ 받아온 해당 날씨 데이터를 바탕으로, API에서 날씨 아이콘 이미지 데이터를 받아옴
				let iconImage = try await repository.fetchWeatherIconImage(withID: currentWeather.weathers.first?.icon ?? "")	

				// 받아온 iconImage 활용! 코드의 흐름이 깔끔해짐.
	  }
}
```


## 내용 추가 업데이트 예정
