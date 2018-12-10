//
//  StateMachine.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/9/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import Foundation

//  =================================================================================================
//  Protocol Definition
//  =================================================================================================
@objc protocol ProfileState {
    func validateInput(completed: Bool)
}

extension ProfileState {
    func validateInput(completed: Bool) {}
}

//  =================================================================================================
//  State Classes
//  =================================================================================================
class InitialState: ProfileState {
    var stateMachine: StateMachine
    
    init(statemachine: StateMachine) {
        self.stateMachine = statemachine
    }
    
    func validateInput(completed: Bool) {
        if completed == true {
            self.stateMachine.setNewState((self.stateMachine.finalState)!)
        } else {
            self.stateMachine.setNewState((self.stateMachine.someInputState)!)
        }
    }
}

class SomeInputReceived: ProfileState {
    var stateMachine: StateMachine

    init(statemachine: StateMachine) {
        self.stateMachine = statemachine
    }
    
    func validateInput(completed: Bool) {
        if completed == true {
            self.stateMachine.setNewState((self.stateMachine.finalState)!)
        }
    }
}

class FinalState: ProfileState {
    var stateMachine: StateMachine

    init(statemachine: StateMachine) {
        self.stateMachine = statemachine
    }
    
    func validateInput(completed: Bool) {
        if completed == false {
            self.stateMachine.setNewState((self.stateMachine.someInputState)!)
        }
    }
}

//  =================================================================================================
//  State Context
//  =================================================================================================
class StateMachine: NSObject {
    @objc dynamic var currentState: ProfileState?
    var initialState: InitialState?
    var someInputState: SomeInputReceived?
    var finalState: FinalState?
    
    override init() {
        super.init()
        initialState = InitialState(statemachine: self)
        someInputState = SomeInputReceived(statemachine: self)
        finalState = FinalState(statemachine: self)
        }
    
    func validate(completed: Bool) {
        currentState?.validateInput(completed: completed)
    }
    
    func setNewState(_ state: ProfileState) {
        self.currentState = state
    }
}
