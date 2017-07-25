# ETAMessages
Class project

- How to test (recommend to do in extended View: ^)

	Launch in Xcode on device iPhone 5s. Set location to Apple:
	Debug->Location->Apple

	Mobile Mode:

		- Tap Enable button:
		  Display changes from "- locationManager..." to local coordinates.

		- Update location via simulator menu:
		  Debug -> Location -> CustomLocation:
		  Blue dot will move to new location, mapView will be centered.


	Stationary Mode with Mobility Simulator:

		- Tap Poll button:
		  Local and Remote coordinates are noted in the display.
		  
		- Tap the Simulate button:
		  Remote user location is noted with a pointAnnotation (red pin)
		  to the left of screen, local user noted with blue dot. eta and
		  distance data is appended to the display. mapView is refreshed,
		  centered between users, span'ed appropriately to cover most of
		  mapView.

		- Remote user (red pin) will incrementally move closer to the
		  blue dot. Remote longitude, eta, and distance will be updated
		  in the display UILabel. A wide, red progress view will appear
		  above the ToolBar along with a centered progressLabel.
		  
		  Both progressView and progressLabel will be updated as the red
		  pin gets closer to the blue dot (decreasing). And will disappear
		  when the pin and dot locations are equal. Fetch and Upload
		  Activity stop.
		  
		- Tap Disable button to reset the app and the screen.
		
	Known Issues:
		- Reloading the app via the txt-msgs app-store may result in
		  corrupted mapView.
		
		
- How did you organize the project's code and resources?

  - Cloud.swift
    Upload, fetch, save, delete a record to/from iCloud repo.
    
    Post-Review Updates:
    - Update upload() to take in whenDone closure , and to call
      back with result whenDone(result). Call publicDatabase.delete()
      directly in upload(), call publicDatabase.save() in success
      path of publicDatabase.delete() closure.
    - Remove semaphore locks in deleteRecord(). Remove saveRecord().
      Re-implement fetchRecord() to take in a whenDone closure, which
      will be called with a packet argument.
    - Update to use the packet.setLocation() methods.
    - Remove pre-comments code.
    - Re-enable an error print().
    
    - Start and Stop upload activity indicator in upload().
    - Add fetchActivity support.
    - Remove print lines. 
    - Convert CloudAdapter to a Container View. Move in fetch and upload
      activity and labels.
    - Take a userUUID: String parameter in fetchRecord() and deleteRecord().
    - Update upload() to 1st fetch, update record, then save. Don't subscribe
      in Extension-App.
    
  - Uploading.swift - New
  	Manage mobile mode behavior, with localUser and single packet
  
    Post-Review Updates:
    - Update uploadLocation() to take in whenDone closure, and to call
      back with result whenDone(result).
    - Remove pre-comments code.
    
    - Take and Pass the upload Activity indicator for uploadLocation()
      calls.
    - Pass in a userUUID: String argument to cloud.deleteRecord().
    - Minor cleanup.
  
  - Users.switf - New
  	Knows user name and location info
  	
  	Post-Review Updates:
    - Create initializer that takes user name and location. Remove separate
      lat/long setters with a single location setter.
    - Remove the name set/getters.
    - Remove pre-comments code.
  	  
  - Poll.swift
    Poll iCloud repo for content changes in remote-User's location record.

    Post-Review Updates:
    - Re-do fetchRemote() to take in a whenDone closure, which is called
      with a packet argument. Update to accomodate optional coordinates.
      Pass a closure to the fetchRemote() call in pollRemote(). Make
      call to eta.getEtaDistance() in closure.
    - Update to use the Location(userName:location) initializer and the
      setLocation() method.
    - Check self.myEta and self.etaOriginal for nil values.
    - Remove pre-comments code.
    - Add support to instantiate PseudoNotificationsViewController on
      ETA == 0.
    - Replace sleep(2) with a DispatchSourceTimer.
    - Cleanup etaNotification(): Create setupLocalNotification() and
      setupPseudoLocalNotification().
    - Fix explicit unwrapping crash in pollRemote().
    - Set self.etaOriginal once myEta is no longer nil.
    - Reduce polling interval to 1700 milli seconds for simulation.
    
    - Note ETA in progress view and progress display. Do not call
      etaNotification().
    - Don't set progressDisplay.textColor to red.
    - Don't update etaProgressView if eta or etaOriginal are nil.
    - Get instance of EtaAdapter. Don't pass Eta Adapter to pollRemote(),
      getEtaDistance()
    - Add fetchActivity support. Move etaProgress and progressDisplay to
      getEtaDistance. Update hasArrivedEta to 60. Don't call etaNotification().
    - Remove references to etaProgress and progressLabel.
    - Remove print lines.
    - Don't update pin, display, or mapView in pollRemote(). Do instead in
      getEtaDistance().
    - Undo previous. Do UI updates in pollRemote().
    - Take in a userUUID: String parameter in fetchRemote() and pollRemote().
      Pass in to cloudRemote.fetchRecord().
      
      
    - Reenable localNotification code.
    
  - MapUpdate.swift
    Manage mapView updates for remote-user pin, map centering and spanning, and
    display updates.

    Post-Review Updates:
    - Update to accomodate the to-optional changes in Location.swift
    - Return the larger of the lat/long deltas in centerView(). Use as
      span delta suggestions in refreshMapView(). Cleanup ternary operator use
      to compute latDistTo and longDisto, and center point coordinates. Add
      a few more cases in the refreshMapView() switch.
    - Remove pre-comments code.
    - Update case value for span deltas.
    - Replace delta switch with:  delta = Float(distance * 0.0000015)
    - Don't remove point annotation if on same location, to reduce
      pin jitter.
      
    - Fix multiple pins issue.
    - Reference eta and distance as class properties of EtaAdapter.
    - Pass eta: Bool vs. EtaAdapter.
    - Remove commented-out lines. Adjust display text tabs and spaces.
  
  - Location.switch
    Location coordinate structure.
    
    Post-Review Updates:
    - Make latitude and longitude optionals.
    - Create constructors that take in userName and Location. Replace
      separate lat/long-setter with a single location setter.
    - Remove pre-comments code.
    
    
  - Eta.swift
    eta value and etaPointer structure.
    moved in getEtaDistance() from MapUpdate.swift
    
    Post-Review Updates:
    - Update getEtaDistance() to update mapView and display within the closure.
    - Note ETA server error: "Directions Not Available"
    - Update print()s.
    - Remove the UnsafeMutableRawPointer.
    - Refresh mapView in case of "Directions Not Available" error in
      mkDirections.calculate().
    - Remove pre-comments code.
    - Add localNotification calls.
    - Set mkDirReq.transportType to .automobile.
    - Track distance vs. eta for simulation.
    - Don't addPin() nor etaAdapter.mapUdate.refreshMapView() on getEtaDistance()
      failure, and add secondString to displayUpdate() to reduce jumpiness.
      
    - Make eta and distance class properties. Don't pass etaAdapter to
      getEtaDistance(). Make mapUpdate calls directly.
    - Move ETA Progress Bar and label into getEtaDistance().
    - Convert EtaAdapter to a Container View. Move etaProgress and progressLabel
      objects to EtaAdapter. Create struct ETAIndicator to hold etaProgress and
      progressLabel for use in getEtaDistance(). Update getEtaDistance() signature to
      remove etaProgress and progressLabel. Add prototype sound-playing code.
    - Don't do pin, display or map updates in getEtaDistance(). Remove print
      lines.
    - Update pin, mapView, and display in getEtaDistance().
    - Getting blue screen at end of simulation, undo preview UI updating
      in getEtaDistance().


  - GPSsLocation.swift
  	Manages local and remote location updates when CLLocation Framework
  	calls locationManager()
  	
  	Post-Review Updates:
  	- Update uploadToIcloud() to take in whenDone closure, and to call
      back with result whenDone(result).
    - Update checkRemote() to take in mapView, EtaAdapter, and display
      parameters for use in the pollRemoteUser.fetchRemote() closure.
    - Remove lat/long-setting in init(). Update checkRemote() to take in
      a closure argument result(Bool). Set remoteUser.location directly to
      packet.
    - Update to not call Users.getName().
    - Remove pre-comments code.
    - Change class name to GPSLocationAdapter.
    - Move in handleUploadResult() and handleCheckRemoteResult() from
      MessagesViewController.swift.
    - Update display in handleUploadResult() only if not polling.
    
    - Take and Pass the upload Activity indicator for uploadToIcloud()
      calls.
    - Get instances of MapUpdate and EtaAdapter. Don't pass EtaAdapter to
      checkRemote(), getEtaDistance(), nor handleCheckRemoteResult().
    - Add fetchActivity support.
    - Remove EtaAdapter references. Remove print and commented-out lines.
      Don't do UI updates if polling enabled.
    - Pass in a userUUID: String argument to pollRemoteUser.fetchRemote().
 
 
  - ETANotifications.swift - New File
    Configure, register, and schedule local notifications.



  - LocalNotificationDelegate.swift - New file.
    Responding to actionable notifications and receiving notifications
    while your app is in the foreground


  - PseudoNotificationsViewController.swift - New file.
    View holding a UILabel to present a blue background and a "Has Arrived"
    message. Instantiated in PollManager.etaNotification() when ETA == 0
    (or close enough).
    
  - MobilitySimulator.swift
    Simulate iPhone device mobility by updating iCloud record directly.
    
    - Reduce step increments to 0.0025 when will jump over destination.
    - Take and Pass the upload Activity indicator for uploadToIcloud()
      calls.
    - Reduce step increments to 0.0005 when will jump over destination.
    - Update location record every 2 sec (vs. 1).
    - Reduce step increments to 0.00025 when will jump over destination.
    - Add a remote paramater to startMobilitySimulator() to note the
      simulation is for the remote location. Also update user's location
      struct fields. Set mobilitySimulatorEnabled to false when stopping
      simulation.
    - Condition all UI updates on !PollManager.enabledPolling.


  - UUIDViewController.swift - New file.
    A Container View Controller containing the URLMessage UILabel.
    Displayed when user taps on the send image. The Remote user's
    UUID will be noted in the URLMessage label.
    
    - Set "remoteUUID" UserDefaults key with messageInUrl value.

  - MessagesViewController.swift
    Manages the UI implemented in IBACtion functions enable() and poll().
    The mobile user enters the app via the Enable button, the stationary
    users does so via the Poll button. Local location changes come in to
    the locationManager() CLLOcation callback function.
    
    A UILabel notes local and remote coordinate data, and eta/distance
    info. At times it reports specific app state, sort of like a console.
    
    Post-Review Updates:
    - Update upload.uploadLocation() call to pass a closure.
      Update gpsLocation.uploadToIcloud() call to pass a closure.
    - Add display argument to gpsLocation.checkRemote() call. Call
      self.pollManager.fetchRemote() with a closure that is called back
      with a packet argument. Call displayUpdate() in main DispatchQueue.
      Move display updates into self.eta.getEtaDistanc() closure.
    - Unwrap locations.last in locationManager(). Set self.localUser.location
      directly to lmPacket per GPSLocation changes. Call
      self.handleUploadResult(result) in self.gpsLocation.uploadToIcloud()
      closure, in locationManager(). Add handleUploadResult() method that
      takes in a closure to process the uploadToIcloud() result, updating
      the display with appropriate messages, and calling gpsLocation.checkRemote()
      if polling had been enabled. Added handleCheckRemoteResult() method that
      takes in a closure to handle the result of the checkRemote() call.
      Call startUpdatingLocation() and enableUploading() in poll() respond to
      stationary user movement during or after polling.
    - Update to use the Location(userName:location) initializer and the
      setLocation() method.
    - Remove pre-comments code.
    - Add viewWillAppear() override. Add delegate for local notifications.
    - Set pollManager.messagesVC property to self to instantiate
      PseudoNotificationsViewController.
    - Change Food button to Simulate add IBAction to mobilitySumulation. Add
      support for mobility-simulation. Remove reseting of poll_enabled.
    - Move out handleUploadResult() and handleCheckRemoteResult() to
      GPSsLocation.swift.
    - Call pollRemote() inside the success path of the fetchRemote() closure,
      right after calling getEtaDistance().

    - Don't refreshMapView() in locationManager() if polling.
    - Plug in Fetch and Upload Activity Indicators, pass in for
      uploadLocation() and uploadToIcloud() calls.
    - Add etaPogress and progressDisplay. Pass to pollRemote().
    - Reduce hight of etaPogress bar. Cleat etaPogress and progressDisplay
      in disable().
    - Increase etaPogress bar height.
    - Remove commented-out code in poll(). Don't call getEtaDistance() in
      pollManager.fetchRemote() success path.
    - Don't need to get an instance of EtaAdapter. Reference eta as class
      property of EtaAdapter without instantiating EtaAdapter. Don't pass
      EtaAdapter to handleUploadResult() nor pollRemote().
    - Add fetchActivity support. Reset vars when in poll(), simulate() and
      disable().
    - Move etaProgress and progressLabel to EtaAdapter Container View controller.
    - Update mobilitySimulator.stopMobilitySimulator() call to coordinate
      with Polling. And vice-versa.
    - Create class property locationManagerEnabled to disable locationManager
      globally.
    - Create localUUID and remoteUUID properties. Extract the remote user's
      UUID from the inserted-image's URLComponent in the willBecomeActive()
      override. Start polling if local user taps on the inserted image. Compose
      and Insert the UUID image in addImage(), which is called in enable().
      Reset local and remote user names to UUID strings in each @IBAction func.
      Break out most of poll() code to startPolling(). Refresh mapview in
      disable().
    - Add locationManager properties: CLActivityType.automotiveNavigation, etc.
      Set "remoteUUID" Userdefault in willBecomeActive and willTransition.
      Disable NSURLSession code.
      
 
 
- What is the project supposed to do?
  In an environment consiting of two mobile devices, the ETAMessages app
  delivers local notification of remote-user's ETA to Stationary device,
  and uploads location data to iCloud from the Mobile-user's device.
  
- What is working?
  All of the above are working as expected. Remote-User location can be
  read from iCloud records, as the devices get closer, the mapView span is
  updated to zoom in. Mobile device location coordinates are updated to
  iCloud repo. ETA and distance data extraction is working.
  
- What is not?
  Can't receive remote or local notifications. This is expected behavior
  for a Messages Extension, will need to incorporate as a target of a
  parent app.
  
- Are there any problems that you know you need to fix?
  
  MapView corruption and missing mapView on some launches.
  
  
- Are there any areas where you would like help?

  Not yet.
  
  
- TODO:
	- Implement local notifications for has-arrived notice.
	- Implement remote notification from iCloud record server.
	- Consider pop-up menu to enable/disable stationary and mobile modes.
	  Or possibly just note if enabled/disabled
	  by changing the button item background?
	  Then Remove the Disable button.
	- Add directions overlay to mapView.

  
