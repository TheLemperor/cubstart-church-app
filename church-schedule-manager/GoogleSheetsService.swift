import Foundation

class GoogleSheetsService {
    // The ID of your Google Sheet - replace with your actual ID
    private let spreadsheetId = "1wyrolLBnocTIFhcMgdTxOOZjKN_a3TzB4bujjqADLIA"
    
    // The range to read from - adjust based on your sheet
    private let range = "'Jadwal Pelayanan'!A1:AM200"
    
    // Your API key (you can get this from Google Cloud Console)
    private let apiKey = "AIzaSyCbzVDyi7sQEOoqGUe6tzAQnXfobKOyl-c"
    
    // Singleton instance
    static let shared = GoogleSheetsService()
    
    private init() {
        // Nothing to initialize
    }
    
    // Read data from Google Sheets
    func readSchedule(completion: @escaping ([ScheduleItem]?, Error?) -> Void) {
        // Construct the URL for the spreadsheet data
        let urlString = "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/\(range)?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "GoogleSheetsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        // Make the request
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "GoogleSheetsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
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
                completion(nil, error)
            }
        }.resume()
    }
    
    // Helper method to parse sheet data into ScheduleItem objects
    private func parseScheduleItems(from values: [[String]]) -> [ScheduleItem] {
        var scheduleItems = [ScheduleItem]()
        
        // Skip the header row
        guard values.count > 1 else { return [] }
        let headerRow = values[0]
        let dataRows = Array(values.dropFirst())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy" // Adjust based on your date format
        
        for row in dataRows {
            // Ensure we have at least a date column
            guard row.count > 0 else { continue }
            
            // Parse date from first column
            guard let dateString = row[safe: 0], !dateString.isEmpty else {
                continue
            }
            
            // Try different date formats
            var date: Date?
            
            // Try the default format first
            date = dateFormatter.date(from: dateString)
            
            // If that fails, try alternative formats
            if date == nil {
                let alternativeFormats = ["M/d/yyyy", "yyyy-MM-dd", "dd/MM/yyyy"]
                for format in alternativeFormats {
                    let formatter = DateFormatter()
                    formatter.dateFormat = format
                    if let parsedDate = formatter.date(from: dateString) {
                        date = parsedDate
                        break
                    }
                }
            }
            
            // Skip if we couldn't parse the date
            guard let validDate = date else { continue }
            
            // Iterate through each column and create a schedule item if there's a person assigned
            for (columnIndex, _) in row.enumerated() {
                // Skip date and note columns (first two columns)
                if columnIndex < 2 { continue }
                
                // Check if we have a role name from the header and a person assigned
                guard columnIndex < headerRow.count,
                      let roleName = headerRow[safe: columnIndex],
                      !roleName.isEmpty,
                      let assignedPerson = row[safe: columnIndex],
                      !assignedPerson.isEmpty else {
                    continue
                }
                
                // Create a schedule item
                let item = ScheduleItem(date: validDate, role: roleName, assignedPerson: assignedPerson)
                scheduleItems.append(item)
            }
        }
        
        return scheduleItems
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
