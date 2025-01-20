import Combine
import UIKit

class EventManager {
    static let shared = EventManager()

    enum Event {
        case showImages(imageDataUrls: [String])
    }

    let eventPublisher = PassthroughSubject<Event, Never>()
}
