package
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.media.Camera;
    import flash.media.Microphone;
    import flash.media.Video;
    import flash.media.SoundCodec;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.system.Security;
    import flash.system.SecurityPanel;
    import flash.utils.Timer;
    import flash.utils.Dictionary;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    //import com.adobe.images.JPGEncoder;
    import flash.utils.ByteArray;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLRequest;
    import flash.net.URLLoader;
	import flash.display.Sprite;

    /**
     * WebcamRecorder uses the user's webcam and/or microphone to record
     * video and/or audio and stream it to a Wowza server which then stores
     * it. It can play the recorded video or sound, and send notifications
     * about its state to a provided Javascript listener.
     * 
     * @see flash.media.Camera
     * @see flash.media.Microphone
     * @see flash.media.Video
     * @see flash.net.NetConnection
     * @see flash.net.NetStream
     */
    public class Main extends Sprite {
          
        /** Recording mode using the microphone to record audio */
        public static const SPEEX : String = SoundCodec.SPEEX;
        public static const NELLYMOSER : String = SoundCodec.NELLYMOSER;

		
        
        // ----------------------------------------------------------------------------------------------------------------------
        // VARS
        // ----------------------------------------------------------------------------------------------------------------------
        
        private var _detectOnly : String;
        private var _hasCamera : Boolean;
        private var _hasMicrophone : Boolean;
     
		private var _state: String;

        private var _serverConnection : NetConnection;
		private var _playServerConnection : NetConnection;
		

        private var _currentRecordId : String;
        private var _previousRecordId : String;

		
		private var _videoPreview : Video;
        private var _webcam : Camera;
        private var _microphone : Microphone;
        private var _publishStream : NetStream;
        private var _playStream : NetStream;
		
        private var _notificationTimer : Timer;
        private var _recordingTimer : Timer;
        private var _playingTimer : Timer;
        private var _flushBufferTimer : Timer;
		private var _initTimer : Timer;

		private var _stage:Stage;
		private var _config: AppConfig;
		private var _log: LogService;
		private var _notifications: NotificationService;

        
         
        public function Main() {
            
			_log = new LogService();
			_stage = stage;
			_config = new AppConfig(stage.loaderInfo.parameters);
			
			_log.info('Webcam recorder v0.3');
			
			// Check log
			_config.validate(_log);
			
			_notifications = new NotificationService(_log, _config.jsListener);
			
			// Extenral interface
            setUpJSApi();

			
			 // Add the video preview
            _videoPreview = new Video(_config.width, _config.height);
            _videoPreview.smoothing = true;

            stageResizeHandler();
			_stage.addChildAt(_videoPreview, 0);
			
            _stage.addEventListener(Event.RESIZE, stageResizeHandler);

            // Set up the timers
            _recordingTimer = new Timer( 1000 );
            _playingTimer = new Timer( 1000 );
			
			// notification frequency
			if( _config.notificationFrequency == 0 ) {
                _log.warn('init - notificationFrequency has to be greater or equal to zero! We won\' notify for this session.' );
            }
			else
			{
				var notificationInterval: Number = (1 / _config.notificationFrequency) * 1000;
				_log.debug('notificationInterval' + notificationInterval + 'ms');
				
                _notificationTimer = new Timer(notificationInterval);
                _notificationTimer.start();
            }

			
			//init on complete
			_stage.loaderInfo.addEventListener(Event.COMPLETE, init);
			init();
		
        }


		public function init(event:Event = null): void {
			
			_stage.removeEventListener(Event.COMPLETE, init);
			
			setState(AppStates.INIT);
			
			_hasCamera = setupWebcam();
			_hasMicrophone = setupMic();
			
			if (!_hasCamera) {
				setErrorState("No camera available");
				return;
			}
			
            if (!_hasMicrophone) {
				setErrorState("No microphone available");
				return;
			}     
                                    

			// Connect to the server
			_serverConnection = new NetConnection();
			_serverConnection.addEventListener( NetStatusEvent.NET_STATUS, onConnectionStatus );
				
			connect();

            //setState(AppStates.READY);
		}
		
		/** Set up the JS API */
        private function setUpJSApi():void
        {
            if( !ExternalInterface.available )
            {
                _log.warn('setUpJSApi - ExternalInterface not available!');
                return;
            }
            
            Security.allowDomain('*');
            ExternalInterface.addCallback( 'record', record );
            ExternalInterface.addCallback( 'stopRecording', stopRecording );

            ExternalInterface.addCallback( 'play', play );
            ExternalInterface.addCallback( 'seek', seek );
            ExternalInterface.addCallback( 'pausePlaying', pausePlaying );
            ExternalInterface.addCallback( 'detectHighestResolution', detectHighestResolution );

            ExternalInterface.addCallback( 'currentFPS', currentFPS);
			ExternalInterface.addCallback( 'getState', getState);
			ExternalInterface.addCallback( 'getRecordingTime', getRecordingTime);
            ExternalInterface.addCallback( 'hasCamera', hasCamera);
			ExternalInterface.addCallback( 'hasMicrophone', hasMicrophone);
            ExternalInterface.addCallback( 'showSettings', showSettings);
            ExternalInterface.addCallback( 'remainingBufferLength', remainingBufferLength);
			
            _log.info('JS API initialized');
        }
        
		public function connect():void {
		
			_log.debug('Connecting to: ' + _config.serverURL);
			_serverConnection.connect(_config.serverURL);
		}
		
		private function isSettingsDialogVisible(): Boolean {
			
			var closed:Boolean = true;
			var dummy:BitmapData;
			dummy = new BitmapData(1, 1);

			try
			{
				// Try to capture the stage: triggers a Security error when the settings dialog box is open
				dummy.draw(stage);
				return false
			}
			catch (error:SecurityError)
			{
				return true;
			}
			finally {
				dummy.dispose();
				dummy = null; 
			}
			
			return true;

		}
		
		private function checkReadyState(event:Event = null): Boolean {
			
			if (isSettingsDialogVisible()) {
				_log.debug('checkReadyState : settings dialog is still visible');
				return false;
			}
			
			
			if (!_webcam || !_microphone) {
				_log.debug('checkReadyState : webcan or mics not available');
				return false;
			}
			
			if (_webcam.muted || _microphone.muted) {
				showSettings();
				
				_log.debug('checkReadyState : webcam/mics are muted');
				return false;
			}
			

			_log.debug('checkReadyState : All good');			
			
			//kill the init timer if defined
			if (_initTimer) {
				_initTimer.stop();
				_initTimer = null;
			}
			
			setState(AppStates.READY);
			return true;
		}
		
		
        public function showSettings():void {
			Security.showSettings( SecurityPanel.PRIVACY );
        }
		
        public function stageResizeHandler(event:Event = null):void {
            _videoPreview.width = _stage.stageWidth;
            _videoPreview.height = _stage.stageHeight;
		

			// _stage.setChildIndex(_videoPreview, 0);
        }

		public function getRecordingTime(): int {
			return _recordingTimer.currentCount;
		}
		
		public function getState(): String {
			return _state;
		}
		
        public function hasCamera():Boolean {
            return _hasCamera;
        }
		
        public function hasMicrophone():Boolean {
            return _hasMicrophone;
        }
		
		private function checkState(description: String, validState: String ): Boolean  {
			if (_state === validState) {
				return true;
			}
			
			_log.error(description + " : invalid state : expected [" + validState + "], found [" + _state + "]");
			return true;
		}
		
		private function checkStates(description: String, validStates: Array): Boolean {
			
			for (var i:int = 0; i < validStates.length; i++){
				if (_state === validStates[i]) {
					return true;
				}

			}

			_log.error(description + " : invalid state : expected [" + 'multiple' + "], found [" + _state + "]");
			return false;
		}
		
        public function record( recordId:String ):Boolean
        {
			if (!checkState('record', AppStates.READY)) {
				return false;
			}
			
            // Error if we are already recording
            if( !recordId || recordId.length == 0 ) {
                _log.error('record - recordId must be a non-empty string' );
                return false;
            }
            
            // If there is a playback in progress, we stop it
            if( _playStream ) {
                _log.info('record - Stopped playback to record' );
                stopPlayStream();
            }
            
            // Start recording and dispatch a notification
            _currentRecordId = recordId;
			
			if (!startPublishStream( recordId, false )) {
				return false;
			}
			
			setState(AppStates.RECORDING);
			return true;
		}
        
		/*
        public function stillRecord(url:String, quality:int = 100):void
        {
            var data:BitmapData = new BitmapData(_webcam.width,_webcam.height);
            data.draw(_videoPreview);

            var encoder:JPGEncoder = new JPGEncoder(quality);
            var byteArray:ByteArray = encoder.encode(data); 
            var header:URLRequestHeader = new URLRequestHeader("Content-type", "image/jpeg");
            var request:URLRequest = new URLRequest(url);
            request.requestHeaders.push(header);
            request.method = URLRequestMethod.POST;
            request.data = byteArray;
            
            var urlLoader:URLLoader = new URLLoader();
            urlLoader.addEventListener(Event.COMPLETE, sendComplete);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            urlLoader.load(request);
            
            function sendComplete(event:Event):void {
                notify(STILL_SENT, urlLoader.data);
            }                    
            
            function errorHandler(event:Event):void {
                notify(STILL_SEND_ERROR, urlLoader.data);
            }
        }
		*/

        /** Stop the current recording without the possibility to resume it. */
        public function stopRecording():Boolean
        {
			if (!checkState('record', AppStates.RECORDING)) {
				return false;
			}
			

            // Stop the publish stream if necessary
            if( _publishStream ) {
                stopPublishStream();
			}
            
            // Memorize the recordId
            _previousRecordId = _currentRecordId;
            _currentRecordId = null;
            
            // Dispatch a notification
            setState(AppStates.DONE);
            
            // Reset the recording time
            _recordingTimer.reset();
			
			return true;
        }
        
        
        
        
        /**
         * Go to the keyframe closest to the specified time.
         * 
         * @param time Number: Time to seek (in seconds).
         */
        public function seek( time:Number ):void
        {
            if( !_playStream ) {
                _log.error('seek - Not playing anything!' );
                return;
            }
            
            _playStream.seek( time );
        }
        
       
		
        public function remainingBufferLength():Number {
            if (_publishStream) {
                return _publishStream.bufferLength;
            } else {
                return -1;
            }
        }

        private function detectHighestResolution(width:int, height:int, framerate:int, favorArea:Boolean):Dictionary
        {
            var webcam:Camera = Camera.getCamera();
            webcam.setMode(width, height, framerate, favorArea);

            var dict:Dictionary = new Dictionary();
            dict["width"] = webcam.width;
            dict["height"] = webcam.height;
            dict["framerate"] = webcam.fps;

            return dict;
        }

        /** Set up the player */
        private function currentFPS():int
        {
            return _webcam.currentFPS;
        }
        
        // ----------------------------------------------------------------------------------------------------------------------
        // PRIVATE METHODS
        // ----------------------------------------------------------------------------------------------------------------------
                
        /**
         * Listen to the server connection status. Set up the JS API
         * if the connection was successful.
         */
        private function onConnectionStatus( event:NetStatusEvent ):void
        {
			_log.info(event.info.code + ": "+ event.info.description);
			
            if ( event.info.code == "NetConnection.Connect.Success" )
			{
                setUpRecording();
			}
				
			if ( event.info.code == "NetConnection.Connect.Closed" )
			{
				_log.debug("reconnecting");
                connect();
			}
				
            else if( event.info.code == "NetConnection.Connect.Failed" || event.info.code == "NetConnection.Connect.Rejected" )
                _log.error('Couldn\'t connect to the server. Error: ' + event.info.description );
        }
        
		private function setupWebcam():Boolean {

			_webcam = Camera.getCamera();
			if (!_webcam) {
				return false;
			}
			
			_webcam.setMode(_config.width, _config.height, _config.framerate, true);
			_webcam.setQuality(_config.bandwidth, _config.quality );
			_webcam.setKeyFrameInterval( _config.framerate );
			_webcam.addEventListener(StatusEvent.STATUS, notifyCameraEnabled);
			
			_log.debug("Camera attached");
            _videoPreview.attachCamera( _webcam );
			return true;
		}
		
		private function setupMic(): Boolean {

			_microphone = Microphone.getMicrophone();
			
			if (!_microphone) {
				return false;
			}
			
			_microphone.addEventListener(NetStatusEvent.NET_STATUS, notifyMicrophoneEnabled);
			_microphone.rate = _config.audiorate;
			_microphone.codec = _config.audiocodec;
			_microphone.setSilenceLevel(0);
			
			if (_config.audiocodec == SoundCodec.SPEEX) {
				_microphone.encodeQuality = _config.audioquality;
				_microphone.framesPerPacket = 1;
			}
			
			return true;

			/*
			// Just to trigger the security window when initializing the component in audio mode
			if (_serverConnection) {
				var testStream : NetStream = new NetStream( _serverConnection );
				testStream.attachAudio( _microphone );
				testStream.attachAudio( null );
			}
			*/
		}
        
        /** Set up the recording device(s) (webcam and/or microphone) */
        private function setUpRecording():void
        {
			_log.debug("setUpRecording");
			

			if (!checkReadyState()) {
				_initTimer = new Timer( 500 );
				_initTimer.addEventListener(TimerEvent.TIMER, checkReadyState);
				_initTimer.start();	
			}
        }
        
        /** Set up the player */
        private function setUpPlaying():void
        {
            _videoPreview.attachCamera( null );
            _videoPreview.attachNetStream( _playStream );
        }
        
        private function setState( state:String, msg:String = null):void
        {
			_state = state;
			_notifications.notifyState(state, msg);
        }
		
		private function setErrorState(msg: String): void
		{
			setState(AppStates.ERROR, msg);
		}

        /** Trigger the sending of a notification to the JS listener */
        private function notify( type:String = null, arguments:Object = null ):void
        {
			_notifications.notifyEvent(type, arguments);
        }

        /** Notify camera enabled */
        private function notifyCameraEnabled( event:StatusEvent ):void
        {
            _notifications.notifyEvent(AppEvents.CAMERA_ENABLED, event.code.substr(7).toLowerCase());
        }
        

        /** Notify camera enabled */
        private function notifyMicrophoneEnabled( event:StatusEvent ):void
        {
            _notifications.notifyEvent(AppEvents.MICROPHONE_ENABLED, event.code.substr(7).toLowerCase());
        }
        
        /** Notify of the recording time */
        private function notifyRecordingTime( event:Event ):void
        {
            _notifications.notifyTime( AppEvents.RECORDING_TIME, _recordingTimer.currentCount );
        }
        
        /** Notify of the played time */
        private function notifyPlayedTime( event:Event  = null):void
        {
			if (_playStream) {
				_log.debug(_playStream.bufferLength);
				
				if (_playStream.bufferLength == 0) {
					_log.debug('buffer empty');
				}
			}
            _notifications.notifyTime( AppEvents.PLAYBACK_TIME, _playingTimer.currentCount);
        }
        
        /**
         * Start the publish stream.
         * 
         * @param recordId String: The name of the recorded file.
         * @param append Boolean: true if we resume an existing recording, false otherwise.
         */
        private function startPublishStream( recordId:String, append:Boolean ):Boolean
        {

			try
			{
				_log.info("recording stared: " +recordId);
				
				// Set up the publish stream
				_publishStream = new NetStream( _serverConnection );
				_publishStream.client = {};
				
				// Start the recording
				_publishStream.publish( recordId, append?"append":"record" );
				
				// Attach the devices
				_publishStream.attachCamera( _webcam );
				_publishStream.attachAudio( _microphone );
				
				// Set the buffer
				_publishStream.bufferTime = _config.recordBufferTime;
				
				// Start incrementing the recording time and dispatching notifications
				_recordingTimer.start();
				if (_notificationTimer){
					_notificationTimer.addEventListener( TimerEvent.TIMER, notifyRecordingTime );
				}
				
				return true;
			}
			catch (e: *) {
				_publishStream = null;
				return false;
			}
			
			return false;
			
        }
        
        /** Stop the publish stream or monitor the buffer size */
        private function stopPublishStream():void
        {
            // Detach the devices
            _publishStream.attachCamera( null );
            _publishStream.attachAudio( null );
            
            // Stop the recording or delay if the buffer is not empty
            if( _publishStream.bufferLength == 0 ) {
                doStopPublishStream();
                
            } else {
                _flushBufferTimer = new Timer( 250 );
                _flushBufferTimer.addEventListener( TimerEvent.TIMER, checkBufferLength );
                _flushBufferTimer.start();
            }
            
            // Stop incrementing the recording time and dispatching notifications
            if (_notificationTimer) {
                  _notificationTimer.removeEventListener( TimerEvent.TIMER, notifyRecordingTime );
             }
            _recordingTimer.stop();
        }
        
        /** Check the buffer length and stop the publish stream if empty */
        private function checkBufferLength( event:Event ):void
        {
            // Do nothing if the buffer is still not empty
            if( _publishStream.bufferLength > 0 )
                return;
            
            // If the buffer is empty, destroy the timer
            _flushBufferTimer.removeEventListener( TimerEvent.TIMER, checkBufferLength );
            _flushBufferTimer.stop();
            _flushBufferTimer = null;
            
            // Then actually stop the publish stream
            doStopPublishStream();
        }
        
        /** Actually stop the publish stream */
        private function doStopPublishStream():void
        {
            _publishStream.publish( null );
            _publishStream = null;
        }
        
		/**
         * Play the previous recording. You have to call <code>stopRecording()</code>
         * before being able to call <code>play()</code>.
         * 
         * @see #stopRecording()
         */
        public function play():Boolean
        {
			if (!checkState('play', AppStates.DONE )) {
				return false;
			}
			
			if( !_previousRecordId ) {
				_log.error('play - Nothing recorded yet. You have to call stopRecording() before play().' );
				return false;
			}
				
            // If we already started playing, we just resume, dispatch a notification and restore scheduled notifications
            if( _playStream ) {
                _playStream.resume();
				_log.debug("playStream resumed");
            }
			else if (!startPlayStream( _previousRecordId ))
			{
				return false;
			}
			
			// Start incrementing the played time and dispatching notifications
            _playingTimer.start();
            if (_notificationTimer)
			{
                _notificationTimer.addEventListener( TimerEvent.TIMER, notifyPlayedTime );
            }
			
			setState(AppStates.PLAYBACK);

            // Start the play stream
			return true;
        }
		
		 /** Pause the current playback */
        public function pausePlaying():Boolean
        {
			if (!_playStream) {
				return false;
			}
			
			_playStream.time;

			_playStream.pause();
			_log.debug("playStream paused");
			
            // Dispatch a notification
			setState(AppStates.DONE);
            
            // Stop incrementing the played time and dispatching notifications
			if (_notificationTimer) {
				_notificationTimer.removeEventListener( TimerEvent.TIMER, notifyPlayedTime );
			}
			
			 _playingTimer.stop();
			 
			return true;
        }
        
		       //On status events from a NetStream object 
        private function onPlayStatus( event:NetStatusEvent ):void 
        { 
            _log.debug( "Status event from " + event.target.info.uri + " at " + event.target.time ); 
            //handle status events 
        } 
		
        /**
         * Start the play stream.
         * 
         * @param playId String: The name of the file to play.
         */
        public function startPlayStream( playId:String ):Boolean
        {
			_log.debug("play " + playId);
			
            // Set up the play stream
            _playStream = new NetStream( _serverConnection );
            _playStream.client = {};
            _playStream.bufferTime = 2;
            
            // Replace the webcam preview by the stream playback
            setUpPlaying();
			
            _playStream.addEventListener(StatusEvent.STATUS, onPlayStatus);
			
            // Add an event listener to dispatch a notification and go back to the webcam preview when the playing is finished
            _playStream.client.onPlayStatus = function( info:Object ):void
            {
				
				
				_log.debug("onPlayStatus: " + info.code);
				
                if ( info.code == "NetStream.Play.Complete" )
				{
                    pausePlaying();
					_playStream = null;
					
				}
            }
            
			_playingTimer.reset();
			
            // Start the playback
            _playStream.play( playId );
			return true;
        }
        
        /** Stop the play stream */
        private function stopPlayStream():void
        {

            // setUpRecording();
        }
    }
}