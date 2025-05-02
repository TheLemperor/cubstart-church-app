import Foundation

class GoogleSheetsService {

    private let spreadsheetId = "1wyrolLBnocTIFhcMgdTxOOZjKN_a3TzB4bujjqADLIA"
    
    private let range = "'Jadwal Pelayanan'!A1:AM200"
    
    private let apiKey = "AIzaSyCbzVDyi7sQEOoqGUe6tzAQnXfobKOyl-c"
    
    static let shared = GoogleSheetsService()
    
    private init() {
        // Nothing to initialize
    }
    
    func readSchedule(completion: @escaping ([ScheduleItem]?, Error?) -> Void) {
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "GoogleSheetsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.timeoutIntervalForRequest = 60.0
        sessionConfig.timeoutIntervalForResource = 120.0
        
        let session = URLSession(configuration: sessionConfig)
        
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "GoogleSheetsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response (first 500 chars): \(responseString.prefix(500))")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let values = json["values"] as? [[String]] {
                    let scheduleItems = self.parseScheduleItems(from: values)
                    completion(scheduleItems, nil)
                } else {
                    completion(nil, NSError(domain: "GoogleSheetsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"]))
                }
            } catch {
                print("JSON Parsing Error: \(error.localizedDescription)")
                completion(nil, error)
            }
        }.resume()
    }
    
    private func parseScheduleItems(from values: [[String]]) -> [ScheduleItem] {
        var scheduleItems = [ScheduleItem]()
        
        // Skip the header row
        guard values.count > 1 else {
            print("Error: Not enough rows in the spreadsheet (only found header row)")
            return []
        }
        
        let headerRow = values[0]
        print("Header row: \(headerRow)")
        
        let dataRows = Array(values.dropFirst())
        print("Found \(dataRows.count) data rows")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        // Get current date
        let currentDate = Calendar.current.startOfDay(for: Date())
        print("Current date for filtering: \(currentDate)")
        
        for (rowIndex, row) in dataRows.enumerated() {
            print("Processing row \(rowIndex + 1): \(row)")
            
            guard row.count > 0 else {
                print("Skipping row \(rowIndex + 1): Empty row")
                continue
            }
            
            guard let dateString = row[safe: 0], !dateString.isEmpty else {
                print("Skipping row \(rowIndex + 1): No date value")
                continue
            }
            
            print("Trying to parse date: \(dateString)")
            
            var date: Date?
            
            date = dateFormatter.date(from: dateString)
            
            if date == nil {
                let alternativeFormats = ["M/d/yyyy", "yyyy-MM-dd", "dd/MM/yyyy"]
                for format in alternativeFormats {
                    print("Trying alternative format: \(format)")
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let parsedDate = formatter.date(from: dateString) {
                        date = parsedDate
                        print("Successfully parsed date using format: \(format)")
                        break
                    }
                }
            }
            
            guard let validDate = date else {
                print("Failed to parse date: \(dateString)")
                continue
            }
            
            let startOfDay = Calendar.current.startOfDay(for: validDate)
            
            if startOfDay < currentDate {
                print("Skipping past date: \(startOfDay)")
                continue
            }
            
            // Iterate through each column and create a schedule item if there's a person assigned
            for (columnIndex, _) in row.enumerated() {
                if columnIndex < 2 { continue }
                
                guard columnIndex < headerRow.count,
                      let roleName = headerRow[safe: columnIndex],
                      !roleName.isEmpty else {
                    print("Skipping column \(columnIndex): No role name in header")
                    continue
                }
                
                guard let assignedPerson = row[safe: columnIndex],
                      !assignedPerson.isEmpty else {
                    continue
                }
                
                print("Creating schedule item: \(validDate) - \(roleName) - \(assignedPerson)")
                
                let item = ScheduleItem(date: validDate, role: roleName, assignedPerson: assignedPerson)
                scheduleItems.append(item)
            }
        }
        
        print("Total schedule items created: \(scheduleItems.count)")
        return scheduleItems
    }}
    extension Array {
        subscript(safe index: Index) -> Element? {
            return indices.contains(index) ? self[index] : nil
        }
    }
