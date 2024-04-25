// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
pragma solidity ^0.8.25;

contract TeachingContract{

    /* Errors */
    error TeachingContract__InsufficientTuition();
    error TeachingContract__NotOwner();
    error TeachingContract__NotAcceptingEnrollment();
    error TeachingContract__WrongKey();

    /* Type Declarations */
    enum Enrollment{
        ACCEPTING,
        FULL
    }

    /* State variables */
    //ChainlinkVRF

    //Classroom variables
    address private immutable i_owner; 
    address payable private s_studentAddress;
    uint256 private s_studentBalance;
    bytes32 private s_classroomKey;
    Attendance private s_studentAttendance; 

    /* Events */
    event CheckedAttendance(uint256 indexed requestId);
    event StudentEnrolled(address indexed student);
    event StudentAttendedClass(address indexed student);

    /* Modifiers */
    modifier onlyOwner(){
        if (msg.sender != i_owner){
            revert TeachingContract__NotOwner();
        }
        _;
    }
    modifier classroomLock(uint256 key){
        if (key != s_classroomKey){
            revert TeachingContract__WrongKey();
        }
        _;
    }
    modifier checkEnrollment(){
        if (s_studentAddress != address(0)){
            revert TeachingContract__NotAcceptingEnrollment("Student already enrolled");
        }
        _;
    }

    /* Functions */
    constructor(){
        i_owner = msg.sender;
    }
    /* */

    function enroll() external payable checkEnrollment{
        //Checks

        //Effects
        s_studentAddress = msg.sender;


    }
    /* Should be called by perform upkeep function in order to subtract from the student balance
    in the event that the student hasn't entered the "classroom"
     */
    function checkAttendance() private{

    }

    /**Getters */
    function getOwner() public view returns (address){
        return i_owner;
    }
    function getStudent() public view returns (address){
        return s_studentAddress;
    }

    function getAttendance() public view returns (Attendance){
        return s_studentAttendance;
    }
    
    function getisEnrollmentOpen() public view returns (Enrollment){
        return s_takingStudents;
    }
}


