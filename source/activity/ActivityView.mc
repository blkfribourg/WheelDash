import Toybox.ActivityRecording;
using Toybox.FitContributor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Timer;
using Toybox.Time;
using Toybox.Math;

class ActivityRecordDelegate extends WatchUi.BehaviorDelegate {
  private var _view as ActivityRecordView?;

  //! Constructor
  //! @param view The app view
  public function initialize(view) {
    BehaviorDelegate.initialize();
    _view = view;
  }
  public function setView(view as ActivityRecordView) {}
  //! On menu event, start/stop recording
  //! @return true if handled, false otherwise
  public function onMenu() as Boolean {
    return true;
  }

  function onKey(keyEvent) {
    if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
      if (Toybox has :ActivityRecording) {
        if (!_view.isSessionRecording()) {
          _view.startRecording();
        } else {
          _view.stopRecording();
        }
      }
    }
    if (keyEvent.getKey() == WatchUi.KEY_ESC) {
      WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
    return true;
  }

  function onPreviousPage() {
    // WatchUi.switchToView(main_view, main_delegate, WatchUi.SLIDE_UP); // Switch to
    WatchUi.popView(WatchUi.SLIDE_DOWN);
    return true;
  }
}

class ActivityRecordView extends WatchUi.View {
  private var accuracy = [
    "not available",
    "last know GPS fix",
    "Poor GPS fix",
    "Usable GPS fix",
    "Good GPS fix",
  ];
  private var accuracy_msg = "";

  private var fitTimer;
  private var _session as Session?;
  private var startingMoment as Time.Moment?;
  private var startingEUCTripDistance;

  //! Constructor
  public function initialize() {
    View.initialize();

    if (fitTimer == null) {
      fitTimer = new Timer.Timer();
    }
    accuracy_msg = accuracy[Position.getInfo().accuracy];
  }

  //! Stop the recording if necessary
  public function stopRecording() as Void {
    eucData.activityRecording = false;

    if (
      Toybox has :ActivityRecording &&
      isSessionRecording() &&
      _session != null
    ) {
      _session.stop();
      _session.save();
      _session = null;
      WatchUi.requestUpdate();
    }
    if (fitTimer != null) {
      fitTimer.stop();
    }
  }

  //! Start recording a session
  public function startRecording() as Void {
    eucData.activityRecording = true;

    _session = ActivityRecording.createSession({
      :name => "EUC riding",
      :sport => ActivityRecording.SPORT_GENERIC,
    });
    setupFields();
    _session.start();
    resetVariables();
    initSessionVar();
    if (fitTimer != null) {
      //System.println("FITtimerStarted");
      fitTimer.start(method(:updateFitData), 1000, true);
    }
    WatchUi.requestUpdate();
  }
  function initSessionVar() {
    startingMoment = new Time.Moment(Time.now().value());
    startingEUCTripDistance = eucData.correctedTotalDistance;
    minVoltage = eucData.getVoltage();
    maxVoltage = minVoltage;
    minBatteryPerc = eucData.getBatteryPercentage();
    maxBatteryPerc = minBatteryPerc;
  }

  public function onLayout(dc as Dc) as Void {}

  public function onHide() as Void {
    if (eucData.activityRecording == false) {
      //System.println("Stopping sensors");
      Position.enableLocationEvents(
        Position.LOCATION_DISABLE,
        method(:onPosition)
      );
      eucData.GPS_requested = false;
    }
  }

  //! Restore the state of the app and prepare the view to be shown.
  public function onShow() as Void {
    //System.println("starting sensors");
    enableGPS();
  }
  function enableGPS() {
    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
  }
  function onPosition(info as Info) as Void {}

  //! Update the view
  //! @param dc Device context
  public function onUpdate(dc as Dc) as Void {
    accuracy_msg = accuracy[Position.getInfo().accuracy];
    // Set background color
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    dc.clear();
    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    dc.drawText(
      dc.getWidth() / 2,
      0,
      Graphics.FONT_XTINY,
      "GPS:\n" + accuracy_msg,
      Graphics.TEXT_JUSTIFY_CENTER
    );

    if (Toybox has :ActivityRecording) {
      // Draw the instructions
      if (!isSessionRecording()) {
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
          dc.getWidth() / 2,
          dc.getHeight() / 2,
          Graphics.FONT_MEDIUM,
          "Press OK to\nStart Recording",
          Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
      } else {
        var x = dc.getWidth() / 2;
        var y = dc.getFontHeight(Graphics.FONT_XTINY) * 2;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.drawText(
          x,
          y,
          Graphics.FONT_MEDIUM,
          "Recording...",
          Graphics.TEXT_JUSTIFY_CENTER
        );
        y += dc.getFontHeight(Graphics.FONT_MEDIUM);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawText(
          x,
          y,
          Graphics.FONT_MEDIUM,
          "Press OK again\nto Stop and Save\nthe Recording",
          Graphics.TEXT_JUSTIFY_CENTER
        );
      }
    } else {
      // tell the user this sample doesn't work
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
      dc.drawText(
        dc.getWidth() / 2,
        dc.getWidth() / 2,
        Graphics.FONT_MEDIUM,
        "This product doesn't\nhave FIT Support",
        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
      );
    }
  }

  public function isSessionRecording() as Boolean {
    if (_session != null) {
      return _session.isRecording();
    }
    return false;
  }

  // Field ID from resources.
  const SPEED_FIELD_ID = 0;
  const PWM_FIELD_ID = 1;
  const VOLTAGE_FIELD_ID = 2;
  const CURRENT_FIELD_ID = 3;
  const POWER_FIELD_ID = 4;
  const TEMP_FIELD_ID = 5;
  const TRIPDISTANCE_FIELD_ID = 6;
  const MAXSPEED_FIELD_ID = 7;
  const MAXPWM_FIELD_ID = 8;
  const MAXCURRENT_FIELD_ID = 9;
  const MAXPOWER_FIELD_ID = 10;
  const MAXTEMP_FIELD_ID = 11;
  const AVGSPEED_FIELD_ID = 12;
  const AVGCURRENT_FIELD_ID = 13;
  const AVGPOWER_FIELD_ID = 14;
  const EORBATTERY_FIELD_ID = 15;

  const MINVOLTAGE_FIELD_ID = 16;
  const MAXVOLTAGE_FIELD_ID = 17;
  const MINBATTERY_FIELD_ID = 18;
  const MAXBATTERY_FIELD_ID = 19;
  const MINTEMP_FIELD_ID = 20;
  const WHEELNAME_FIELD_ID = 21;

  const SPEED_FIELD_ID_MILES = 22;
  const TRIPDISTANCE_FIELD_ID_MILES = 23;
  const MAXSPEED_FIELD_ID_MILES = 24;
  const AVGSPEED_FIELD_ID_MILES = 25;

  const TEMP_FIELD_ID_K = 26;
  const MINTEMP_FIELD_ID_K = 27;
  const MAXTEMP_FIELD_ID_K = 28;

  hidden var mSpeedField;
  hidden var mPWMField;
  hidden var mVoltageField;
  hidden var mCurrentField;
  hidden var mPowerField;
  hidden var mTempField;
  hidden var mTripDistField;
  hidden var mMaxSpeedField;
  hidden var mMaxPWMField;
  hidden var mMaxCurrentField;
  hidden var mMaxPowerField;
  hidden var mMaxTempField;
  hidden var mMinTempField;
  hidden var mAvgSpeedField;
  hidden var mAvgCurrentField;
  hidden var mAvgPowerField;
  hidden var mEORBatteryField;
  hidden var mMinVoltageField;
  hidden var mMaxVoltageField;
  hidden var mMinBatteryField;
  hidden var mMaxBatteryField;
  hidden var mWheelName;

  // Initializes the new fields in the activity file
  function setupFields() {
    if (eucData.useMiles == true) {
      mSpeedField = _session.createField(
        "current_speed",
        SPEED_FIELD_ID_MILES,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "mph" }
      );
      mTripDistField = _session.createField(
        "current_TripDistance",
        TRIPDISTANCE_FIELD_ID_MILES,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "miles" }
      );
      mMaxSpeedField = _session.createField(
        "session_Max_speed",
        MAXSPEED_FIELD_ID_MILES,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "mph" }
      );
      mAvgSpeedField = _session.createField(
        "session_Avg_Speed",
        AVGSPEED_FIELD_ID_MILES,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "mph" }
      );
    } else {
      mSpeedField = _session.createField(
        "current_speed",
        SPEED_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "km/h" }
      );
      mTripDistField = _session.createField(
        "current_TripDistance",
        TRIPDISTANCE_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km" }
      );
      mMaxSpeedField = _session.createField(
        "session_Max_speed",
        MAXSPEED_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km/h" }
      );
      mAvgSpeedField = _session.createField(
        "session_Avg_Speed",
        AVGSPEED_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "km/h" }
      );
    }

    mPWMField = _session.createField(
      "current_PWM",
      PWM_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "%" }
    );
    mVoltageField = _session.createField(
      "current_Voltage",
      VOLTAGE_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "V" }
    );
    mCurrentField = _session.createField(
      "current_Current",
      CURRENT_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "A" }
    );
    mPowerField = _session.createField(
      "current_Power",
      POWER_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "W" }
    );
    mMaxPWMField = _session.createField(
      "session_Max_PWM",
      MAXPWM_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
    );
    mMaxCurrentField = _session.createField(
      "session_Max_Current",
      MAXCURRENT_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "A" }
    );
    mMaxPowerField = _session.createField(
      "session_Max_Current",
      MAXPOWER_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "W" }
    );
    if (eucData.useFahrenheit == 1) {
      mTempField = _session.createField(
        "current_Temperature",
        TEMP_FIELD_ID_K,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "°F" }
      );
      mMaxTempField = _session.createField(
        "session_Max_Temperature",
        MAXTEMP_FIELD_ID_K,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "°F" }
      );

      mMinTempField = _session.createField(
        "session_Min_Temperature",
        MINTEMP_FIELD_ID_K,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "°F" }
      );
    } else {
      mTempField = _session.createField(
        "current_Temperature",
        TEMP_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "°C" }
      );
      mMaxTempField = _session.createField(
        "session_Max_Temperature",
        MAXTEMP_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "°C" }
      );

      mMinTempField = _session.createField(
        "session_Min_Temperature",
        MINTEMP_FIELD_ID,
        FitContributor.DATA_TYPE_FLOAT,
        { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "°C" }
      );
    }
    mAvgCurrentField = _session.createField(
      "session_Avg_Current",
      AVGCURRENT_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "A" }
    );
    mAvgPowerField = _session.createField(
      "session_Avg_Power",
      AVGPOWER_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "W" }
    );
    mEORBatteryField = _session.createField(
      "EORBattery",
      EORBATTERY_FIELD_ID,
      FitContributor.DATA_TYPE_UINT8,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
    );

    mMinVoltageField = _session.createField(
      "session_Min_Voltage",
      MINVOLTAGE_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "V" }
    );
    mMaxVoltageField = _session.createField(
      "session_Max_Voltage",
      MAXVOLTAGE_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "V" }
    );
    mMinBatteryField = _session.createField(
      "session_Min_Battery",
      MINBATTERY_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
    );
    mMaxBatteryField = _session.createField(
      "session_Max_Battery",
      MAXBATTERY_FIELD_ID,
      FitContributor.DATA_TYPE_FLOAT,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "%" }
    );
    mWheelName = _session.createField(
      "wheel_Name",
      WHEELNAME_FIELD_ID,
      FitContributor.DATA_TYPE_STRING,
      { :mesgType => FitContributor.MESG_TYPE_SESSION, :count => 32 }
    );
  }
  var maxSpeed = 0.0;
  var maxPWM = 0.0;
  var maxCurrent = 0.0;
  var maxPower = 0.0;
  var maxTemp = 0.0;
  var minTemp = 0.0;
  var currentPWM = 0.0;
  var correctedSpeed = 0.0;
  var currentCurrent = 0.0;
  var currentVoltage = 0.0;
  var currentBatteryPerc = 0.0;
  var sumCurrent = 0.0;
  var callNb = 0.0;
  var currentPower = 0.0;
  var sumPower = 0.0;
  var sessionDistance = 0.0;
  var minVoltage = 0.0;
  var maxVoltage = 0.0;
  var minBatteryPerc = 0.0;
  var maxBatteryPerc = 0.0;
  var avgSpeed = 0.0;
  var avgCurrent = 0.0;
  var avgPower = 0.0;

  function updateFitData() {
    //System.println("updateFit");
    callNb++;
    currentVoltage = eucData.getVoltage();
    currentBatteryPerc = eucData.getBatteryPercentage();
    currentPWM = eucData.PWM;
    correctedSpeed = eucData.correctedSpeed;
    currentCurrent = eucData.getCurrent();
    currentPower = currentCurrent * currentVoltage;

    mSpeedField.setData(correctedSpeed); // id 0
    mPWMField.setData(currentPWM); //id 1
    mVoltageField.setData(currentVoltage); // id 2
    mCurrentField.setData(currentCurrent); // id 3
    mPowerField.setData(currentPower); // id 4
    mTempField.setData(eucData.DisplayedTemperature); // id 5

    if (correctedSpeed > maxSpeed) {
      maxSpeed = correctedSpeed;
      mMaxSpeedField.setData(maxSpeed); // id 7
    }
    if (currentPWM > maxPWM) {
      maxPWM = currentPWM;
      mMaxPWMField.setData(maxPWM); // id 8
    }
    if (currentCurrent > maxCurrent) {
      maxCurrent = currentCurrent;
      mMaxCurrentField.setData(maxCurrent); // id 9
    }
    if (currentPower > maxPower) {
      maxPower = currentPower;
      mMaxPowerField.setData(maxPower); // id 10
    }
    if (eucData.DisplayedTemperature > maxTemp) {
      maxTemp = eucData.DisplayedTemperature;
      mMaxTempField.setData(maxTemp); // id 11
    }
    if (eucData.DisplayedTemperature < minTemp && eucData.temperature != 0.0) {
      minTemp = eucData.DisplayedTemperature;
      mMinTempField.setData(minTemp); // id 11
    }
    if (currentVoltage < minVoltage) {
      minVoltage = currentVoltage;
      mMinVoltageField.setData(minVoltage);
    }
    if (currentVoltage > maxVoltage) {
      maxVoltage = currentVoltage;
      mMaxVoltageField.setData(maxVoltage);
    }
    if (currentBatteryPerc > maxBatteryPerc) {
      maxBatteryPerc = currentBatteryPerc;
      mMaxBatteryField.setData(maxBatteryPerc);
    }
    if (currentBatteryPerc < minBatteryPerc) {
      minBatteryPerc = currentBatteryPerc;
      mMinBatteryField.setData(minBatteryPerc);
    }
    if (currentBatteryPerc > 0 && eucData.paired == true) {
      mEORBatteryField.setData(currentBatteryPerc);
    }
    var currentMoment = new Time.Moment(Time.now().value());
    var elaspedTime = startingMoment.subtract(currentMoment);
    //System.println("elaspsed :" + elaspedTime.value());
    if (elaspedTime.value() != 0 && eucData.totalDistance > 0) {
      if (startingEUCTripDistance < 0) {
        startingEUCTripDistance = eucData.correctedTotalDistance;
      }
      sessionDistance =
        eucData.correctedTotalDistance - startingEUCTripDistance;
      avgSpeed = sessionDistance / (elaspedTime.value() / 3600.0);
    } else {
      sessionDistance = 0.0;
      avgSpeed = 0.0;
    }
    mTripDistField.setData(sessionDistance); // id 6

    mAvgSpeedField.setData(avgSpeed); // id 12
    sumCurrent = sumCurrent + currentCurrent;
    sumPower = sumPower + currentPower;
    mAvgCurrentField.setData(sumCurrent / callNb); // id 13
    mAvgPowerField.setData(sumPower / callNb); // id 14

    //mRunningTimeDebugField.setData(elaspedTime.value());
    mWheelName.setData(eucData.wheelName);
    // add Trip distance from EUC
    WatchUi.requestUpdate();
  }

  function resetVariables() {
    startingMoment = new Time.Moment(Time.now().value());
    startingEUCTripDistance = -1;
    minVoltage = 255.0;
    maxVoltage = 0.0;
    minBatteryPerc = 101.0;
    maxBatteryPerc = 0.0;
    maxSpeed = 0.0;
    maxPWM = 0.0;
    maxCurrent = 0.0;
    maxPower = 0.0;
    minTemp = 255.0;
    maxTemp = -255.0;
    sumCurrent = 0.0;
    sumPower = 0.0;
    avgSpeed = 0.0;
    avgCurrent = 0.0;
    avgPower = 0.0;
    callNb = 0;
  }
}
