//
//  EventProfileHeaderViewModel.swift
//  Sportivity
//
//  Created by Andrzej Frankowski on 25/05/2017.
//  Copyright © 2017 Sportivity. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class EventProfileHeaderViewModel {
    fileprivate let event: Event
    fileprivate let userManager: UserManagerProtocol
    fileprivate let disposeBag = DisposeBag()
    
    let name: Driver<String>
    let photoUrl: Driver<URL?>
    let hostText: Driver<String>
    let placeName: Driver<String?>
    let placeLoc: Driver<Loc?>
    let street: Driver<String?>
    let city: Driver<String?>
    let attendees: Variable<[EventAttendee]>
    let isAttending: Observable<Bool>
    
    let toggleAttend = PublishSubject<Void>()
    
    init(event: Event, userManager: UserManagerProtocol = UserManager()) {
        self.event = event
        self.userManager = userManager
        
        self.name = event.name.asDriver()
//        let placePhoto = event.place.asDriver().flatMap { (place) -> Driver<URL?> in
//            guard let place = place else {
//                return Driver<URL?>.just(nil)
//            }
//            return place.photoURL.asDriver()
//        }
//        let eventPhoto = event.photoUrl.asDriver()
//        photoUrl = Driver.combineLatest(eventPhoto, placePhoto, resultSelector: { (eventPhoto, placePhoto) in
//            return eventPhoto ?? placePhoto
//        })
        photoUrl = event.place.asDriver().map { $0?.photoURL.value }
        let hostText: Observable<String> = event.host.asObservable()
            .flatMap({ (user) -> Observable<String> in
                guard let user = user else { return Observable.just("") }
                return user.name.asObservable()
            })
            .map { (name) -> String in
                return "Organised by: \(name)"
            }
        self.placeName = event.place.asDriver().map { $0?.name.value }
        self.placeLoc = event.place.asDriver().map { $0?.loc.value }
        self.street = event.place.asDriver().map { $0?.street.value }
        self.city = event.place.asDriver().map { $0?.city.value }
        self.hostText = hostText.asDriver(onErrorJustReturn: "")
        self.attendees = event.attendees
        self.isAttending = Observable.combineLatest(userManager.rx_user, attendees.asObservable(), resultSelector: { (user, attendees) -> Bool in
            guard let user = user else { return false }
            return attendees.reduce(false, { (isAttending, attendee) -> Bool in
                return isAttending || attendee.id == user.id
            })
        })
        
        bind()
    }
    
    private func bind() {
        toggleAttend
            .withLatestFrom(isAttending)
            .doOnNext { (isAttending) in
                Logger.shared.log(.info, message: "toggleAttend from isAttending=\(isAttending) to \(!isAttending)")
            }
            .flatMap { (isAttending) -> Observable<Bool> in
                var request: Observable<Void>!
                if isAttending {
                    // POST /attend
                } else {
                    // DELETE /attend //?
                }
                return Observable<Bool>.just(false)
            }
            .subscribeNext { [unowned self] (isAttending) in
                guard let me = self.userManager.user else {
                    assert(false)
                    return
                }
                if isAttending {
                    let meAttendee = EventAttendee(user: me)
                    var newAttendees = self.attendees.value
                    newAttendees.append(meAttendee)
                    self.attendees.value = newAttendees
                } else {
                    let newAttendees = self.attendees.value.filter { $0.id != me.id }
                    self.attendees.value = newAttendees
                }
            }
            .addDisposableTo(disposeBag)
        
    }
}
