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
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);

    function cancelUpkeep(uint256 upkeepId) external;
}

contract TeachingContract is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Errors */
    error TeachingContract__InsufficientTuition();
    error TeachingContract__NotOwner();
    error TeachingContract__NotAcceptingEnrollment();
    error TeachingContract__WrongKey();
    error TeachingContract__NotAStudent();
    error TeachingContract__UpkeepNotNeeded();

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
    uint32 private immutable i_callbackGasLimit;

    //AutomationRegistrar
    LinkTokenInterface private immutable i_link;
    AutomationRegistrarInterface private immutable i_registrar;
    RegistrationParams private s_params;
    uint256 private s_upkeepId;

    //Classroom variables
    uint256 private constant TUITIONFEE = 0.1 ether;
    uint8 private constant PENALTY = 10;
    address private immutable i_owner;
    address payable private s_studentAddress;
    uint8 private s_week;
    uint8 private s_studentBalance;
    uint256 private s_interval;
    uint256 private s_studentPayout;
    uint256 private s_classroomKey;
    uint256 private s_previousLessonTime;
    Attendance private s_studentAttendance;
    Enrollment private s_takingStudents;

    /* Events */
    event CheckedAttendance(uint256 indexed requestId);
    event StudentEnrolled(address indexed student);
    event StudentAttendedClass(address indexed student);
    event UpkeepRegistered(uint256 indexed upkeepId);

    /* Modifiers */ modifier onlyOwner() {
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
    modifier classroomLock(uint256 key) {
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
        bytes32 gasLane,
        uint32 callbackGasLimit,
        RegistrationParams memory params,
        address vrfCoordinator,
        address linkAddress,
        address registrarAddress
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_owner = msg.sender;
        i_link = LinkTokenInterface(linkAddress);
        i_registrar = AutomationRegistrarInterface(registrarAddress);
        s_params = params;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enroll(
        uint8 duration,
        uint8 interval
    ) external payable checkEnrollment {
        if (msg.value < TUITIONFEE) {
            revert TeachingContract__InsufficientTuition();
        }
        s_studentAddress = payable(msg.sender);
        s_studentBalance = 200;
        s_takingStudents = Enrollment.FULL;
        s_interval = interval;
        s_week = duration;
        s_previousLessonTime = block.timestamp;
        //Programatically register an upkeep and start automation
        approveAndRegisterUpkeep();
    }

    function enterClassroom(
        uint256 key
    ) external checkEnrollment onlyStudent classroomLock(key) {
        s_studentAttendance = Attendance.PRESENT;

        emit StudentAttendedClass(msg.sender);
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
        bool enoughTimeElasped = (block.timestamp - s_previousLessonTime) >
            s_interval;
        bool studentAttendingClass = s_takingStudents == Enrollment.FULL;
        bool keyExists = s_classroomKey != 0;
        bool classStillOn = s_week != 0;
        upkeepNeeded =
            enoughTimeElasped &&
            studentAttendingClass &&
            keyExists &&
            classStillOn;
        return (upkeepNeeded, "0x0");
    }

    /**
     * Weekly automation to check if the student showed up this week
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        //If it's the final week of the contract then we want to stop upkeep
        if (!upkeepNeeded) {
            revert TeachingContract__UpkeepNotNeeded();
        }
        if (s_week == 0) {
            resetContractState();
            cancelUpKeep();
            return;
        }
        //If class was not attended: apply penalities
        if (s_studentAttendance == Attendance.ABSENT) {
            s_studentBalance -= PENALTY;
        }
        s_studentAttendance = Attendance.ABSENT;
        s_week -= 1;
        //Generate Key for next week
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit CheckedAttendance(requestId);
    }

    /* Should be called by perform upkeep function in order to subtract from the student balance
    in the event that the student hasn't entered the "classroom"
     */

    function fulfillRandomWords(
        uint256 /* requestId*/,
        uint256[] memory randomWords
    ) internal override {
        //generate the key and save it
        s_classroomKey = randomWords[0];
    }

    function cancelUpKeep() internal {}

    function approveAndRegisterUpkeep() internal {
        //Link must be approved for transfer: either done everytime or done once with infinite approval
        i_link.approve(address(i_registrar), s_params.amount);
        uint256 upkeepId = i_registrar.registerUpkeep(s_params);

        if (upkeepId != 0) {
            s_upkeepId = upkeepId;
        } else {
            revert("Auto approve disabled");
        }
        emit UpkeepRegistered(upkeepId);
    }

    function resetContractState() internal {
        address payable alumni = s_studentAddress;
        //Reset contract to default state
        s_studentAddress = payable(0);
        s_takingStudents = Enrollment.ACCEPTING;
        s_studentPayout = s_studentBalance;
        s_studentBalance = 0;
        s_classroomKey = 0;

        //TODO: cancel upkeep
        //return remaining tuition
        (bool success, ) = alumni.call{value: address(this).balance}("");
        if (!success) {
            revert();
        }
    }

    /**Getters */
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getStudent() public view returns (address) {
        return s_studentAddress;
    }

    function getWeeksRemaining() public view returns (uint8) {
        return s_week;
    }

    function getStudentBalance() public view returns (uint8) {
        return s_studentBalance;
    }

    function getAttendance() public view returns (Attendance) {
        return s_studentAttendance;
    }

    function getisEnrollmentOpen() public view returns (Enrollment) {
        return s_takingStudents;
    }

    function getPreviousLessonTime() public view returns (uint256) {
        return s_previousLessonTime;
    }

    function getClassroomKey() public view onlyOwner returns (uint256) {
        return s_classroomKey;
    }
}
