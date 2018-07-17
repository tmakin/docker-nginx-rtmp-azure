package
{
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
    public class WebcamRecorder extends EventDispatcher {
        
        // ----------------------------------------------------------------------------------------------------------------------
        // CONSTS / CONFIG
        // ----------------------------------------------------------------------------------------------------------------------
        
        /** Recording mode using the webcam to record video and the microphone to record audio */
        public static const VIDEO : String = "video";
        
        /** Recording mode using the microphone to record audio */
        public static const AUDIO : String = "audio";

        /** Recording mode using the microphone to record audio */
        public static const SPEEX : String = SoundCodec.SPEEX;
        public static const NELLYMOSER : String = SoundCodec.NELLYMOSER;

        /** Recording mode */
        private static const DEFAULT_RECORDING_MODE : String = VIDEO;
        
        /** Video framerate */
        private static const DEFAULT_FRAMERATE : uint = 25;

        /** Recording Buffering */
        private static const DEFAULT_RECORD_BUFFER_TIME : uint = 20000;
        
        /** Audio rate */
        private static const DEFAULT_AUDIO_RATE : uint = 44;

        /** Audio codec */
        private static const DEFAULT_AUDIO_CODEC : String = NELLYMOSER;
        
        /** Video width (in pixels) */
        private static const DEFAULT_VIDEO_WIDTH : uint = 1024;
        
        /** Video height (in pixels) */
        private static const DEFAULT_VIDEO_HEIGHT : uint = 768;

        /** Video quality (0-100) */
        private static const DEFAULT_VIDEO_QUALITY : uint = 88;

        /** Audio quality (0-10) when using speex codec */
        private static const DEFAULT_AUDIO_QUALITY : uint = 10;

        /** Video max bandwidth, in bytes per second */
        private static const DEFAULT_VIDEO_BANDWIDTH : uint = 0;        

        /** Default notification frequency : default is  */
        private static const DEFAULT_NOTIFICATION_FREQUENCY : uint = 0;        
        
        // ----------------------------------------------------------------------------------------------------------------------
        // CONSTS / NOTIFICATIONS
        // ----------------------------------------------------------------------------------------------------------------------        
        
        /** Type of the notification dispatched when the object has detected if there is a camera or not*/
        public static const CAMERA : String = "Camera";

        /** Type of the notification dispatched when the object has detected if there is a camera or not*/
        public static const MICROPHONE : String = "Microphone";

        /** Type of the notification dispatched when the user as enabled the camera: the message will be muted / unmuted */
        public static const CAMERA_ENABLED : String = "CameraEnabled";

        /** Type of the notification dispatched when the user as enabled the camera: the message will be muted / unmuted */
        public static const MICROPHONE_ENABLED : String = "MicrophoneEnabled";

        /** Type of the notification dispatched when the object is initialized */
        public static const READY : String = "Ready";
        
        /** Type of the notification dispatched when a recording starts */
        public static const STARTED_RECORDING : String = "StartedRecording";
        
        /** Type of the notification dispatched when a recording pauses */
        public static const PAUSED_RECORDING : String = "PausedRecording";
        
        /** Type of the notification dispatched when a recording stops */
        public static const STOPPED_RECORDING : String = "StoppedRecording";

        /** Type of the notification dispatched when a recording stops */
        public static const FLUSHED_RECORDING : String = "FlushedRecording";
        
        /** Type of the notification dispatched periodically while recording */
        public static const RECORDING_TIME : String = "RecordingTime";
        
        /** Type of the notification dispatched when a playback starts */
        public static const STARTED_PLAYING : String = "StartedPlaying";
        
        /** Type of the notification dispatched when a playback pauses */
        public static const PAUSED_PLAYING : String = "PausedPlaying";
        
        /** Type of the notification dispatched when a playback ends */
        public static const END_PLAYING : String = "EndPlaying";
        
        /** Type of the notification dispatched periodically while playing */
        public static const PLAYED_TIME : String = "PlayedTime";
        
        /** Type of the notification dispatched when a still image is successfully sent */
        public static const STILL_SENT : String = "StillSent";
        /** Type of the notification dispatched when a still image is not successfully sent */
        public static const STILL_SEND_ERROR : String = "StillSendError";
        
        
        // ----------------------------------------------------------------------------------------------------------------------
        // VARS
        // ----------------------------------------------------------------------------------------------------------------------
        
        private var _detectOnly : String;
        private var _hasCamera : Boolean;
        private var _hasMicrophone : Boolean;
        private var _recordingMode : String;
        private var _recordBufferTime : Number; // milliseconds
        private var _serverURL : String;
        private var _serverConnection : NetConnection;
        private var _jsListener : String;
        private var _framerate : uint;
        private var _audiorate : uint;
        private var _audiocodec : String;
        private var _audioquality : uint;
        private var _width : uint;
        private var _height : uint;
        private var _quality : uint;
        private var _bandwidth : uint;
        private var _videoPreview : Video;
        private var _webcam : Camera;
        private var _microphone : Microphone;
        private var _publishStream : NetStream;
        private var _playStream : NetStream;
        private var _currentRecordId : String;
        private var _previousRecordId : String;
        private var _notificationFrequency : uint;
        private var _notificationTimer : Timer;
        private var _recordingTimer : Timer;
        private var _playingTimer : Timer;
        private var _flushBufferTimer : Timer;

		
		private var _stage:Stage;

        // ----------------------------------------------------------------------------------------------------------------------
        // PUBLIC API
        // ----------------------------------------------------------------------------------------------------------------------
        
        /** Constructor: Set up the JS API and read flash vars
         * Flash vars description:
         * <table>
         *         <tr>
         *             <th>Key</th>
         *             <th>Value type</th>
         *             <th>Default value</th>
         *             <th>Description</th>
         *         </tr>
         *         <tr>
         *             <td>detectOnly</td>
         *             <td>String</td>
         *             <td>false</td>
         *             <td>If true, the object won't be usable to record a webcam, but just to detect it with the function "hasCamera"/td>
         *         </tr>
         *         <tr>
         *             <td>serverURL</td>
         *             <td>String</td>
         *             <td>null</td>
         *             <td>The recording server: should look like 'rtmp://localhost/WebcamRecorder' </td>
         *         </tr>
         *         <tr>
         *             <td>recordingMode</td>
         *             <td>String</td>
         *             <td>video</td>
         *             <td>The recording mode. Can be either WebcamRecorder.VIDEO or WebcamRecorder.AUDIO.
         *                 Note that WebcamRecorder.VIDEO includes audio recording if a microphone is available.</td>
         *         </tr>
         *         <tr>
         *             <td>jsListener</td>
         *             <td>String</td>
         *             <td>null</td>
         *             <td>The name of a Javascript listener function able to handle our
         *                 notifications.</td>
         *         </tr>
         *         <tr>
         *             <td>notificationFrequency</td>
         *             <td>Number</td>
         *             <td>0</td>
         *             <td>The frequency at which the recorder will send notifications
         *                 to the JS listener (in Hz).</td>
         *         </tr>
         *         <tr>
         *             <td>framerate</td>
         *             <td>uint</td>
         *             <td>30</td>
         *             <td>The video framerate.</td>
         *         </tr>
         *         <tr>
         *             <td>audiorate</td>
         *             <td>uint</td>
         *             <td>44</td>
         *             <td>The microphone audio rate.</td>
         *         </tr>
         *         <tr>
         *             <td>audiocodec</td>
         *             <td>string</td>
         *             <td>Speex</td>
         *             <td>The microphone codec to use : Speex or NellyMoser.</td>
         *         </tr>
         *         <tr>
         *             <td>audioquality</td>
         *             <td>uint</td>
         *             <td>10</td>
         *             <td>The microphone audio quality when using Speex.</td>
         *         </tr>
         *         <tr>
         *             <td>width</td>
         *             <td>uint</td>
         *             <td>640</td>
         *             <td>The video width.</td>
         *         </tr>
         *         <tr>
         *             <td>height</td>
         *             <td>uint</td>
         *             <td>480</td>
         *             <td>The video height.</td>
         *         </tr>
         *         <tr>
         *             <td>quality</td>
         *             <td>uint</td>
         *             <td>88</td>
         *             <td>The video quality.</td>
         *         </tr>
         *         <tr>
         *             <td>bandwidth</td>
         *             <td>uint</td>
         *             <td>0</td>
         *             <td>The video max bandwidth (default is infinite).</td>
         *         </tr>
         *         <tr>
         *             <td>recordBufferTime</td>
         *             <td>uint</td>
         *             <td>5000</td>
         *             <td>The video recording time in milliseconds (default is 5s).</td>
         *         </tr>
         * </table
         * </table>
         * </table>
         */
         
        public function WebcamRecorder(stage:Stage, serverUrl:String) {
            
			_stage = stage;
			
            _detectOnly = getStringVar("detectOnly", "false");
            _jsListener = getStringVar("jsListener", null);
            _framerate = getUIntVar("framerate", DEFAULT_FRAMERATE);
            _recordBufferTime = getUIntVar("recordBufferTime", DEFAULT_RECORD_BUFFER_TIME) / 1000.0;
            _audiorate = getUIntVar("audiorate", DEFAULT_AUDIO_RATE);
            _audiocodec = getStringVar("audiocodec", DEFAULT_AUDIO_CODEC);
            _audioquality = getUIntVar("audioquality", DEFAULT_AUDIO_QUALITY);
            _width = getUIntVar("width", DEFAULT_VIDEO_WIDTH);
            _height = getUIntVar("height", DEFAULT_VIDEO_HEIGHT);
            _quality = getUIntVar("quality", DEFAULT_VIDEO_QUALITY);
            _bandwidth = getUIntVar("bandwidth", DEFAULT_VIDEO_BANDWIDTH);
            _notificationFrequency = getUIntVar("notificationFrequency", DEFAULT_NOTIFICATION_FREQUENCY);

            setUpJSApi();

            _hasCamera = false;

            if (Camera.names.length > 0) {
                var webcam:Camera = Camera.getCamera();
                if (webcam != null && webcam){
                    _hasCamera = true;
                }
             }

            if (Microphone.names.length > 0) {
                var microphone:Microphone = Microphone.getMicrophone();
                if (microphone != null && microphone){
                    _hasMicrophone = true;
                }
            }

            notify(CAMERA, _hasCamera);
            notify(MICROPHONE, _hasMicrophone);

            if (_detectOnly == "true") {
                return;
            }
                    
            // Set up the config
            //_serverURL  = getStringVar("serverURL", null);
			_serverURL = serverUrl;
            _recordingMode = getStringVar("recordingMode", DEFAULT_RECORDING_MODE);

            // Check the recording mode
            if (!( _recordingMode == VIDEO || _recordingMode == AUDIO)) {
                log( 'error', 'init - recordingMode should be either ' + VIDEO + ' or ' + AUDIO + '(given: ' + _recordingMode + ')' );
                _recordingMode = WebcamRecorder.VIDEO;
            }
                                    
            // Add the video preview
            _videoPreview = new Video(_width, _height);
            _videoPreview.smoothing = true;
            stageResizeHandler();
            _stage.addChild( _videoPreview );
            _stage.addEventListener(Event.RESIZE, stageResizeHandler);

            // Set up the timers
            _recordingTimer = new Timer( 1000 );
            _playingTimer = new Timer( 1000 );

            if (_jsListener != null) {
                setUpJSNotifications(_jsListener);
            }

			setupWebcam();
			
						// Connect to the server
			_serverConnection = new NetConnection();
			_serverConnection.addEventListener( NetStatusEvent.NET_STATUS, onConnectionStatus );
				
            if (_serverURL != null)  {
				connect(_serverURL);
            }

            notify(READY);
        }

		public function connect(serverUrl) {
			
			log("debug", "Connecting to " + serverUrl);
			_serverConnection.connect(_serverURL);
		}
		
        public function showSettings(key:String):void {
            /* keys are defined in SecurityPanel config:
               http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/system/SecurityPanel.html */
            if (key == null) {
                key = SecurityPanel.CAMERA;
            }
            Security.showSettings(key);
        }

        public function stageResizeHandler(event:Event = null):void {
            _videoPreview.width = _stage.stageWidth;
            _videoPreview.height = _stage.stageHeight;
        }

        public function hasCamera():Boolean {
            return _hasCamera;
        }

        private function getStringVar(key:String, value:String):String {
			
			return value;
			
			/*
            if (FlexGlobals.topLevelApplication.parameters.hasOwnProperty(key)) {
                var ret:String = FlexGlobals.topLevelApplication.parameters[key];
                return ret;
            } else {
                return value;
            }
			*/
        }

        private function getUIntVar(key:String, value:int):int {
            return parseInt(getStringVar(key, String(value)));
        }
        
        public function record( recordId:String ):void
        {
			if (!_serverConnection) {
				trace("error", "_serverConnection not defined");
				return;
			}
			
			
            // Error if we are already recording
            if( _publishStream || _currentRecordId ) {
                log( 'error', 'record - Already recording! You have to call stopRecording() before recording again.' );
                return;
            }
            
            if( !recordId || recordId.length == 0 ) {
                log( 'error', 'record - recordId must be a non-empty string' );
                return;
            }
            
            // If there is a playback in progress, we stop it
            if( _playStream ) {
                log( 'info', 'record - Stopped playback to record' );
                stopPlayStream();
            }
            
            // Start recording and dispatch a notification
            _currentRecordId = recordId;
            startPublishStream( recordId, false );
            notify( STARTED_RECORDING );
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
        public function stopRecording():void
        {
            if( !_publishStream && !_currentRecordId ) {
                log( 'error', 'stopRecording - No recording started!' );
                return;
            }
            
            // Stop the publish stream if necessary
            if( _publishStream )
                stopPublishStream();
            
            // Memorize the recordId
            _previousRecordId = _currentRecordId;
            _currentRecordId = null;
            
            // Dispatch a notification
            notify( STOPPED_RECORDING, { time: _recordingTimer.currentCount } );
            
            // Reset the recording time
            _recordingTimer.reset();
        }
        
        /**
         * Stop the current recording with the possibility to resume it.
         * 
         * @see #resumeRecording()
         */
        public function pauseRecording():void
        {
            if( !_publishStream ) {
                log( 'error', 'pauseRecording - Not recording, or recording already paused.' );
                return;
            }
            
            // Stop the publish stream
            stopPublishStream();
            
            // Dispatch a notification
            notify( PAUSED_RECORDING, { time: _recordingTimer.currentCount } );
        }
        
        /**
         * Resume the previously paused recording.
         * 
         * @see #pauseRecording()
         */
        public function resumeRecording():void
        {
            if( !_currentRecordId ) {
                log( 'error', 'resumeRecording - No recording started!' );
                return;
            }
            
            startPublishStream( _currentRecordId, true );
        }
        
        /**
         * Play the previous recording. You have to call <code>stopRecording()</code>
         * before being able to call <code>play()</code>.
         * 
         * @see #stopRecording()
         */
        public function play():void
        {
            // If we already started playing, we just resume, dispatch a notification and restore scheduled notifications
            if( _playStream ) {
                _playStream.resume();
                notify( STARTED_PLAYING );
                _notificationTimer.addEventListener( TimerEvent.TIMER, notifyPlayedTime );
                _playingTimer.start();
                return;
            }
            
            if( _currentRecordId ) {
                log( 'error', 'play - Currently recording. You have to call stopRecording() before play().' );
                return;
            }
            
            if( !_previousRecordId ) {
                log( 'error', 'play - Nothing recorded yet. You have to call stopRecording() before play().' );
                return;
            }
            
            // Start the play stream
            startPlayStream( _previousRecordId );
            
            // Dispatch an notification
            notify( STARTED_PLAYING );
        }
        
        /**
         * Go to the keyframe closest to the specified time.
         * 
         * @param time Number: Time to seek (in seconds).
         */
        public function seek( time:Number ):void
        {
            if( !_playStream ) {
                log( 'error', 'seek - Not playing anything!' );
                return;
            }
            
            _playStream.seek( time );
        }
        
        /** Pause the current playback */
        public function pausePlaying():void
        {
            if( !_playStream ) {
                log( 'error', 'pausePlaying - Not playing anything!' );
                return;
            }
            
            _playStream.pause();
            
            // Dispatch a notification
            notify( PAUSED_PLAYING );
            
            // Stop incrementing the played time and dispatching notifications
            _notificationTimer.removeEventListener( TimerEvent.TIMER, notifyPlayedTime );
            _playingTimer.stop();
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
			log("info", event.info.code + ": "+ event.info.description);
			
            if( event.info.code == "NetConnection.Connect.Success" )
                setUpRecording();
				
            else if( event.info.code == "NetConnection.Connect.Failed" || event.info.code == "NetConnection.Connect.Rejected" )
                log( 'error', 'Couldn\'t connect to the server. Error: ' + event.info.description );
        }
        
        /** Set up the JS API */
        private function setUpJSApi():void
        {
            if( !ExternalInterface.available )
            {
                log( 'warn', 'setUpJSApi - ExternalInterface not available: the Flex component won\'t be reachable from Javascript!');
                return;
            }
            
            Security.allowDomain('*');
            ExternalInterface.addCallback( 'record', record );
            ExternalInterface.addCallback( 'pauseRecording', pauseRecording );
            ExternalInterface.addCallback( 'stopRecording', stopRecording );
            ExternalInterface.addCallback( 'resumeRecording', resumeRecording );
            ExternalInterface.addCallback( 'play', play );
            ExternalInterface.addCallback( 'seek', seek );
            ExternalInterface.addCallback( 'pausePlaying', pausePlaying );
            ExternalInterface.addCallback( 'detectHighestResolution', detectHighestResolution );

            ExternalInterface.addCallback( 'currentFPS', currentFPS);
            //ExternalInterface.addCallback( 'stillRecord', stillRecord);
            ExternalInterface.addCallback( 'hasCamera', hasCamera);
            ExternalInterface.addCallback( 'showSettings', showSettings);
            ExternalInterface.addCallback( 'remainingBufferLength', remainingBufferLength);

            log( 'info', 'JS API initialized' );
        }
        
        /** Set up the JS notifications */
        private function setUpJSNotifications( jsListener:String):void
        {
            // Set up the notifications
            _jsListener = jsListener;

            // Check the notification frequency
            if( !( _notificationFrequency >= 0 ) )
                log( 'warn', 'init - notificationFrequency has to be greater or equal to zero! We won\' notify for this session.' );
            
            if( _notificationFrequency > 0 ) {
                _notificationTimer = new Timer( (1/_notificationFrequency)*1000 );
                _notificationTimer.start();
            }
        }

		private function setupWebcam():void {
			if ( _webcam ) {
				return;
			}
				
			_webcam = Camera.getCamera();
			_webcam.setMode(_width, _height, _framerate, true);
			_webcam.setQuality(_bandwidth, _quality );
			_webcam.setKeyFrameInterval( _framerate );
			_webcam.addEventListener(StatusEvent.STATUS, notifyCameraEnabled);
			
			log("debug", "Camera attached");
            _videoPreview.attachCamera( _webcam );
		}
        
        /** Set up the recording device(s) (webcam and/or microphone) */
        private function setUpRecording():void
        {
			log("debug", "setUpRecording");
			
            // Video (if necessary)	
			if (_webcam.muted) {
				showSettings('privacy');
			}else{
				notify( CAMERA_ENABLED, "unmuted");
			}
            
            // Audio
            if( !_microphone ) {
                _microphone = Microphone.getMicrophone();
                
                if (_microphone != null && _microphone) {
                    if (! _microphone.muted) {
                        notify( MICROPHONE_ENABLED, "unmuted");
                    }

                    _webcam.addEventListener(StatusEvent.STATUS, notifyMicrophoneEnabled);
                    _microphone.rate = _audiorate;
                    _microphone.codec = _audiocodec;
                    _microphone.setSilenceLevel(0);
                    if (_audiocodec == SPEEX) {
                        _microphone.encodeQuality = _audioquality;
                        _microphone.framesPerPacket = 1;
                    }

                    // Just to trigger the security window when initializing the component in audio mode
                    if (_serverConnection) {
                        var testStream : NetStream = new NetStream( _serverConnection );
                        testStream.attachAudio( _microphone );
                        testStream.attachAudio( null );
                    }
                }
            }
        }
        
        /** Set up the player */
        private function setUpPlaying():void
        {
            _videoPreview.attachCamera( null );
            _videoPreview.attachNetStream( _playStream );
        }
        
        /** Trace a log message and forward it to the Javascript console */
        private function log( level:String, msg:String ):void
        {
            trace( level.toLocaleUpperCase() + ' :: ' + msg );
            if( ExternalInterface.available )
                ExternalInterface.call( 'console.'+level, msg );
        }
        
        /** Trigger the sending of a notification to the JS listener */
        private function notify( type:String = null, arguments:Object = null ):void
        {
            if( !_jsListener || !ExternalInterface.available )
                return;

            ExternalInterface.call( _jsListener, type, arguments );
        }

        /** Notify camera enabled */
        private function notifyCameraEnabled( event:StatusEvent ):void
        {
            notify( CAMERA_ENABLED, event.code.substr(7).toLowerCase());
        }
        

        /** Notify camera enabled */
        private function notifyMicrophoneEnabled( event:StatusEvent ):void
        {
            notify( MICROPHONE_ENABLED, event.code.substr(7).toLowerCase());
        }
        
        /** Notify of the recording time */
        private function notifyRecordingTime( event:Event ):void
        {
            notify( RECORDING_TIME, { time: _recordingTimer.currentCount } );
        }
        
        /** Notify of the played time */
        private function notifyPlayedTime( event:Event ):void
        {
            notify( PLAYED_TIME, { time: _playingTimer.currentCount } );
        }
        
        /**
         * Start the publish stream.
         * 
         * @param recordId String: The name of the recorded file.
         * @param append Boolean: true if we resume an existing recording, false otherwise.
         */
        private function startPublishStream( recordId:String, append:Boolean ):void
        {

            // Set up the publish stream
            _publishStream = new NetStream( _serverConnection );
            _publishStream.client = {};
            
            // Start the recording
            _publishStream.publish( recordId, append?"append":"record" );
            
            // Attach the devices
            _publishStream.attachCamera( _webcam );
            _publishStream.attachAudio( _microphone );
            
            // Set the buffer
            _publishStream.bufferTime = _recordBufferTime;
            
            // Start incrementing the recording time and dispatching notifications
            _recordingTimer.start();
            if (_notificationTimer){
                _notificationTimer.addEventListener( TimerEvent.TIMER, notifyRecordingTime );
            }
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
            notify(FLUSHED_RECORDING, null);
        }
        
        /** Stop the playback and go back to the webcam preview when the playback ends */
        private function onPlaybackEnd():void
        {
            // Dispatch a notification
            notify( END_PLAYING, { time: _playingTimer.currentCount } );
            
            // Reset the playing timer and stop scheduled notifications
            if (_notificationTimer) {
                _notificationTimer.removeEventListener( TimerEvent.TIMER, notifyPlayedTime );
            }
            _playingTimer.stop();
            _playingTimer.reset();
            
            // Stop playing stream
            stopPlayStream();
        }
        
        /**
         * Start the play stream.
         * 
         * @param playId String: The name of the file to play.
         */
        private function startPlayStream( playId:String ):void
        {
            // Set up the play stream
            _playStream = new NetStream( _serverConnection );
            _playStream.client = {};
            _playStream.bufferTime = 2;
            
            // Replace the webcam preview by the stream playback
            setUpPlaying();
            
            // Add an event listener to dispatch a notification and go back to the webcam preview when the playing is finished
            _playStream.client.onPlayStatus = function( info:Object ):void
            {
                if( info.code == "NetStream.Play.Complete" )
                    onPlaybackEnd();
            }
            
            // Start the playback
            _playStream.play( _previousRecordId );
            
            // Start incrementing the played time and dispatching notifications
            _playingTimer.start();
            if (_notificationTimer) {
                _notificationTimer.addEventListener( TimerEvent.TIMER, notifyPlayedTime );
            }
        }
        
        /** Stop the play stream */
        private function stopPlayStream():void
        {
            _playStream.pause();
            _playStream = null;
            setUpRecording();
        }
    }
}