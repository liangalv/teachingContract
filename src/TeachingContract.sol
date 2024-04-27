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

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

contract TeachingContract is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Errors */
    error TeachingContract__InsufficientTuition();
    error TeachingContract__NotOwner();
    error TeachingContract__NotAcceptingEnrollment();
    error TeachingContract__WrongKey();
    error TeachingContract__NotAStudent();

    /* Type Declarations */
    enum Enrollment {
        ACCEPTING,
        FULL
    }
    enum Attendance {
        ABSENT,
        PRESENT
    }

    /* State variables */
    //ChainlinkVRF
    uint16 private constant REQUEST_CONFIRMATIONS = 2;
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGaaLimit;

    //Classroom variables
    uint256 private constant TUITIONFEE = 0.1 ether;
    uint256 private constant PENALTY = 10;
    address private immutable i_owner;
    uint256 private immutable i_interval;
    address payable private s_studentAddress;
    uint8 private s_week;
    uint256 private s_studentBalance;
    bytes32 private s_classroomKey;
    Attendance private s_studentAttendance;
    Enrollment private s_takingStudents;

    /* Events */
    event CheckedAttendance(uint256 indexed requestId);
    event StudentEnrolled(address indexed student);
    event StudentAttendedClass(address indexed student);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert TeachingContract__NotOwner();
        }
        _;
    }
    modifier onlyStudent() {
        if (msg.sender != s_studentAddress) {
            revert TeachingContract__NotAStudent();
        }
        _;
    }
    modifier classroomLock(bytes32 key) {
        if (key != s_classroomKey) {
            revert TeachingContract__WrongKey();
        }
        _;
    }
    modifier checkEnrollment() {
        if (s_studentAddress != address(0)) {
            revert TeachingContract__NotAcceptingEnrollment();
        }
        _;
    }

    /* Functions */
    constructor(
        uint64 subscriptionId,
        uint8 numWeeks,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinator
    ) VRFConsumerBaseV2(vrfCoordinator) {
        s_week = numWeeks;
        i_owner = msg.sender;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
    }

    /* */

    function enroll() external payable checkEnrollment {
        if (msg.value < TUITIONFEE) {
            revert TeachingContract__InsufficientTuition();
        }
        s_studentAddress = payable(msg.sender);
        s_studentBalance = 200;
        s_takingStudents = Enrollment.FULL;
        //Interactions: Spin off the automation
    }

    /**
     *@dev This function that the Chainlink Keeper nodes call looking for "upkeepNeeded" to return true
     The following returns true in order for checkUpKeep to return true
     1. A week has passed since the previous lesson
     2. There's a student attending the class
     3. There's been a classroom key generated 
     4. The semester is still going on
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        upkeepNeeded = true;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //If class was attended
        if (s_studentAttendance == Attendance.PRESENT) {}
    }

    /* Should be called by perform upkeep function in order to subtract from the student balance
    in the event that the student hasn't entered the "classroom"
     */

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        //generate the key and save it
        s_classroomKey = keccak256(abi.encodePacked(randomWords[0]));
    }

    function checkAttendance() private {}

    /**Getters */
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getStudent() public view returns (address) {
        return s_studentAddress;
    }

    function getAttendance() public view returns (Attendance) {
        return s_studentAttendance;
    }

    function getisEnrollmentOpen() public view returns (Enrollment) {
        return s_takingStudents;
    }

    function getClassroomKey() public view onlyOwner returns (bytes32) {
        return s_classroomKey;
    }
}
