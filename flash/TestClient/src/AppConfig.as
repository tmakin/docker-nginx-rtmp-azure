package
{
	import flash.media.SoundCodec;
	import flash.display.Stage;
	
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
	public class AppConfig
	{
		/** Recording mode using the webcam to record video and the microphone to record audio */
		public static const VIDEO:String = "video";
		
		/** Recording mode using the microphone to record audio */
		public static const AUDIO:String = "audio";
		
		// ----------------------------------------------------------------------------------------------------------------------
		// CONSTS / CONFIG
		// ----------------------------------------------------------------------------------------------------------------------
		
		public static const DEFAULT_SERVER_URL:String = "rtmp://localhost/test";
		
		/** Recording mode */
		private static const DEFAULT_RECORDING_MODE:String = VIDEO;
		
		/** Video framerate */
		private static const DEFAULT_FRAMERATE:uint = 25;
		
		/** Recording Buffering */
		private static const DEFAULT_RECORD_BUFFER_TIME:uint = 20000;
		
		/** Audio rate */
		private static const DEFAULT_AUDIO_RATE:uint = 44;
		
		/** Audio codec */
		private static const DEFAULT_AUDIO_CODEC:String = SoundCodec.NELLYMOSER;
		
		/** Video width (in pixels) */
		private static const DEFAULT_VIDEO_WIDTH:uint = 1024;
		
		/** Video height (in pixels) */
		private static const DEFAULT_VIDEO_HEIGHT:uint = 768;
		
		/** Video quality (0-100) */
		private static const DEFAULT_VIDEO_QUALITY:uint = 88;
		
		/** Audio quality (0-10) when using speex codec */
		private static const DEFAULT_AUDIO_QUALITY:uint = 10;
		
		/** Video max bandwidth, in bytes per second */
		private static const DEFAULT_VIDEO_BANDWIDTH:uint = 0;
		
		/** Default notification frequency : default is  */
		private static const DEFAULT_NOTIFICATION_FREQUENCY:uint = 2;
		
		public var recordingMode:String;
		public var recordBufferTime:Number; // milliseconds
		public var serverURL:String;
		public var jsListener:String;
		public var framerate:uint;
		public var audiorate:uint;
		public var audiocodec:String;
		public var audioquality:uint;
		public var width:uint;
		public var height:uint;
		public var quality:uint;
		public var bandwidth:uint;
		public var notificationFrequency:uint;
		
		private var _params:Object;
		
		public function AppConfig(params:Object)
		{
			_params = params;
			
			serverURL = getStringVar("serverURL", DEFAULT_SERVER_URL);
			
			recordingMode = getStringVar("recordingMode", DEFAULT_RECORDING_MODE);
			jsListener = getStringVar("jsListener", null);
			framerate = getUIntVar("framerate", DEFAULT_FRAMERATE);
			recordBufferTime = getUIntVar("recordBufferTime", DEFAULT_RECORD_BUFFER_TIME) / 1000.0;
			audiorate = getUIntVar("audiorate", DEFAULT_AUDIO_RATE);
			audiocodec = getStringVar("audiocodec", DEFAULT_AUDIO_CODEC);
			audioquality = getUIntVar("audioquality", DEFAULT_AUDIO_QUALITY);
			width = getUIntVar("width", DEFAULT_VIDEO_WIDTH);
			height = getUIntVar("height", DEFAULT_VIDEO_HEIGHT);
			quality = getUIntVar("quality", DEFAULT_VIDEO_QUALITY);
			bandwidth = getUIntVar("bandwidth", DEFAULT_VIDEO_BANDWIDTH);
			notificationFrequency = getUIntVar("notificationFrequency", DEFAULT_NOTIFICATION_FREQUENCY);
		}
		
		public function validate(log:LogService):void
		{
			
			// Check the recording mode
			if (!(recordingMode == VIDEO || recordingMode == AUDIO))
			{
				log.error('init - recordingMode should be either ' + VIDEO + ' or ' + AUDIO + '(given: ' + recordingMode + ')');
				recordingMode = VIDEO;
			}
		}
		
		private function getStringVar(key:String, value:String):String
		{
			
			if (_params.hasOwnProperty(key))
			{
				var ret:String = _params[key];
				return ret;
			}
			else
			{
				return value;
			}
		}
		
		private function getUIntVar(key:String, value:int):int
		{
			return parseInt(getStringVar(key, String(value)));
		}
		
		private function getBooleanVar(key:String, value:Boolean):Boolean
		{
			return getStringVar(key, String(value)) == "true";
		}
	}

}